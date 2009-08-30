class Lamd
  include Expect


  def accept_host
    "www.lamd.uscourts.gov"
  end


  def accept?(download)
    download.request_uri == "http://www.lamd.uscourts.gov/Opinions/All-opinions.asp"
  end


  def request
    DownloadRequest.new("http://www.lamd.uscourts.gov/Opinions/All-opinions.asp")
  end


  def date_convert(year, month, day)
	
	if month.match("January")
		month = "01"
	elsif month.match("February")
		month = "02"
	elsif month.match("March")
		month = "03"
	elsif month.match("April")
		month = "04"
	elsif month.match("May")
		month = "05"
	elsif month.match("June")
		month = "06"
	elsif month.match("July")
		month = "07"
	elsif month.match("August")
		month = "08"
	elsif month.match("September")
		month = "09"
	elsif month.match("October")
		month = "10"
	elsif month.match("November")
		month = "11"
	elsif month.match("December")
		month = "12"
	end

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

    unless table = doc.at("body").at("font[@face='Verdana, Arial']").search("table")[1]
      raise Exception.new("Unable to find main table")
    end

    rows = table.search("tr")

    rows.each do |x|
			
		column = x.search("td")

		entry = Document.new

		entry.dockets << column[0].at("a").inner_text

		entry.name = column[1].inner_text

		#entry.opinion_by = column[2].inner_text

		alt = x.search("font")
		month = alt[0].inner_text.strip.gsub("....Released on?", "").strip
		day = (alt[2].inner_text.strip.match(/\d{1,2},/)[0])[0...-1]
		year = alt[2].inner_text.strip.match(/\d{4}/)[0]
		entry.date = date_convert(year, month, day)
 
		link = ""
		link << column[0].at("a[@href]").attributes['href']
		entry.add_link("pdf", link)
		receiver << entry
	
     end
    
  end

end
