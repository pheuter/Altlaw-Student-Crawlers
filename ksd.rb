# Crawler for the Federal District Court of Kansas
# Contributor: Alexander Lam (lambchop468 *AT* gmail.com)
# Changelog:
# July 26, 2009: First Revision
# August 14, 2009: Fixed bug: BASEURL contained Opinions.pl? which is incorrect.
# August 14, 2009: Changed regex that splits cell 2 into the Docket and Case Name to use the match() function.
# August 17, 2009: Alec Benzer pointed out that https://ecf.ksd.uscourts.gov/cgi-bin/Opinions.pl would return cases from all years, allowing simplification of much of the fetch code.
# August 17, 2009: Added support for 'subject' field for document.
class Ksd
	BASEURL = "https://ecf.ksd.uscourts.gov/cgi-bin/"
	OPINIONS = "Opinions.pl"
	include Expect
	def accept_host
		"ecf.ksd.uscourts.gov"
	end
	def accept?(download)
		isValid = download.request_uri == BASEURL + OPINIONS
	end
	def request
		pages = [DownloadRequest.new(BASEURL + OPINIONS)]
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
			row.at("td[2]").inner_html =~ %r@(.*) Case No\. (\d+-\d+)<br />(.*)@
			doc.subject = $1
			doc.dockets << $2
			doc.name = $3
                        doc.add_link("application/pdf", BASEURL + row.at("td[3] a").attributes['href'])
                        doc.court = "http://id.altlaw.org/courts/us/fed/dist/ksd"
                        receiver << doc
                end

	end
end
