class Cod
	include Expect
	OPNIONS_PAGE = "http://cod.uscourts.gov/Judges/Opinions.aspx"
	def accept_host
		"www.cod.uscourts.gov"
	end
	def accept?(download)
		download.request_uri == OPINIONS_PAGE
	end
	def request
		[DownloadRequest.new("http://cod.uscourts.gov/Judges/Opinions.aspx")]
	end
	def parse(download, reciever)
		html = download.response_body_as('US-ASCII')
		doc = Hpricot(html)
		unless table = doc.at("table#ctl00_MainContent_Table_op")
	        	raise Exception.new("Could not find main table.")
		end
		rows = table.search("tr")
		first_row = rows.shift
		date_posted_heading = first_row.at("td[1]").inner_text
		match(date_posted_heading, "Date Posted")
		date_filed_heading = first_row.at("td[2]").inner_text
		match(date_filed_heading, "Date Filed")
		case_number_heading = first_row.at("td[3]").inner_text
		match(case_number_heading, "Case Number")
		case_name_heading = first_row.at("td[4]").inner_text
		match(case_name_heading, "Case Name")
		rows.each do |row|
			document = Document.new
			date_string = row.at("td[2]").inner_text
			date_string =~ %r{(\d{1,2})/(\d{1,2})/(\d{4})}
			date = Date.new($3.to_i, $1.to_i, $2.to_i)
			document.date = date
			document.name = row.at("td[4]").inner_text
			document.dockets << row.at("td[3]").inner_text
			url = "http://www.cod.uscourts.gov/" + row.at("td[4] a").attributes['href']
			document.add_link("applicant/pdf", url)
			document.court = "http://id.altlaw.org/courts/us/fed/dist/cod"
			reciever << document
		end
	end
end	
