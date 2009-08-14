class Als
  include Expect


  def accept_host
    "www.als.uscourts.gov"
  end


  def accept?(download)
    download.request_uri == "http://www.als.uscourts.gov/opinions/opinions.cfm"
  end


  def request
    DownloadRequest.new("http://www.als.uscourts.gov/opinions/opinions.cfm")
  end


  def date_convert(date)
	year = date[-4..-1]

	date = date[0...-5]
	dash = date =~ /\//
	month = date[0...dash]
	day = date[dash+1..-1]

	if month.length == 1
		month = "0" << month
	end
	if day.length == 1
		day = "0" << day
	end
	
	return year << "-" << month << "-" << day
  end


  def parse(download, receiver)
    doc = Hpricot(download.response_body_as('US-ASCII'))

    unless table = doc.at("body").at("div[@id='wrapper']").at("div[@id='page_content']").at("table[@id='opinions']")
      raise Exception.new("Unable to find main table")
    end

    rows = table.search("tr")
    rows.shift

    rows.each do |x|
			
		column = x.search("td")

		entry = Document.new

		#entry.dockets << column[1].("a").attributes['href'].match(/\d{2}-\w{2}-\d{4,5}/)[0]

		entry.name = column[1].at("a").inner_text

		entry.opinion_by = column[2].inner_text

		entry.date = date_convert(column[0].inner_text)

		link = "http://www.als.uscourts.gov/" 
		link << (column.at("a").attributes['href'])[1..-1]
		entry.add_link("pdf", link)
		receiver << entry
	
     end
    
  end

end
