# Crawler for the Federal District Court of Kansas
# Contributor: Alexander Lam (lambchop468 *AT* gmail.com)
# Changelog:
# July 26, 2009: First Revision
# August 14, 2009: Fixed bug: BASEURL contained Opinions.pl? which is incorrect.
# August 14, 2009: Changed regex that splits cell 2 into the Docket and Case Name to use the match() function.
class Ksd
	START_DATE = 2005 #the first year that opinions were available.
	CURRENT_DATE = Time.now.year
	#CURRENT_DATE = 2009
	CURRENT_YEAR = "currentYear"
	BASEURL = "https://ecf.ksd.uscourts.gov/cgi-bin/"
	OPINIONS = "Opinions.pl?"
	include Expect
	def accept_host
		"ecf.ksd.uscourts.gov"
	end
	# How the opinions are laid out on the website:
	# The script at https://ecf.ksd.uscourts.gov/cgi-bin/Opinions.pl? can be passed various years, such as:
	#   https://ecf.ksd.uscourts.gov/cgi-bin/Opinions.pl?2008
	# The script also can be passed currentYear, which of course resolves to the current year.
	#   https://ecf.ksd.uscourts.gov/cgi-bin/Opinions.pl?currentYear
	# However, it is not necessary to use currentYear. One can just use the actual numerical year.
	
	# This method tests for all the forms of requests to the script described above.
	def accept?(download)
		isValid = false
		(START_DATE .. CURRENT_DATE).each do |year|
			isValid |= download.request_uri == BASEURL + OPINIONS + year.to_s
		end
		isValid |= download.request_uri == BASEURL + OPINIONS + CURRENT_YEAR
	end
	def request
		pages = []
		(START_DATE ... CURRENT_DATE).each do |year|
			pages += [DownloadRequest.new(BASEURL + OPINIONS + year.to_s)]
		end
		pages += [DownloadRequest.new(BASEURL + OPINIONS + CURRENT_YEAR)]
	end
	#The headers in the table of cases.
	HEADINGS = [" Date Filed", " Case", " Opinion", " Judge"]
	def parse (download, receiver)
                html = Hpricot(download.response_body_as('US-ASCII'))
                unless table1 = html.at("table#table1")
                        raise Exception.new('Main Table (with CSS ID "table1") could not be found.')
                end
                rows = table1.search("tr")
                headcells = []
		rows.shift.search("th") do |cell|
				headcells << cell.inner_text
		end
                match(HEADINGS.size, headcells.size)
                (0 ... headcells.size).each do |cell|
                        match(HEADINGS[cell], headcells[cell])
                end
                rows.each do |row|
                        doc = Document.new
                        matchedDate = match(row.at("td[1]").inner_text, %r@(\d{2})/(\d{2})/(\d{4})@)
                        doc.date = Date.new(matchedDate[3].to_i, matchedDate[1].to_i, matchedDate[2].to_i)
                        row.at("td[2]").inner_html =~ %r@(.*)<br />(.*)@
                        doc.dockets << $1
                        doc.name = $2
			matchedInfo = match(row.at("td[2]").inner_html, %r@(.*)<br />(.*)@)
			doc.dockets << matchedInfo[1]
			doc.name = matchedInfo[2]
                        doc.add_link("application/pdf", BASEURL + row.at("td[3] a").attributes['href'])
                        doc.court = "http://id.altlaw.org/courts/us/fed/dist/ksd"
                        receiver << doc
                end

	end
end
