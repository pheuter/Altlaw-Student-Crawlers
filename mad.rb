class Mad
  include Expect


  def accept_host
    "www.mad.uscourts.gov"
  end


  def accept?(download)
    download.request_uri == "http://pacer.mad.uscourts.gov/recentopinions.html"
  end


  def request
    DownloadRequest.new("http://pacer.mad.uscourts.gov/recentopinions.html")
  end


  def date_convert(date)
	month = date.match(/\d{2}/)[0]
	day = date[3..4]
	year = "20"
	year << date[6..7]
	
	return year << "-" << month << "-" << day
  end


  def parse(download, receiver)
    doc = Hpricot(download.response_body_as('US-ASCII'))

    unless table = doc.at("body").at("div[@align='left']").at("table")
      raise Exception.new("Unable to find main table")
    end

    rows = table.search("tr")
    rows.shift

    rows.each do |x|
			
		column = x.search("td")

		entry = Document.new

		#entry.dockets << column[1].("a").attributes['href'].match(/\d{2}-\w{2}-\d{4,5}/)[0]

		entry.name = column[3].at("font").inner_text

		entry.opinion_by = column[1].inner_text

		entry.date = date_convert(column[2].at("font").inner_text)

		link = column.at("a").attributes['href']
		entry.add_link("pdf", link)
		receiver << entry
	
     end
    
  end

end
