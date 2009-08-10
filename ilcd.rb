class Ilcd
  include Expect

  def accept_host
    "www.ilcd.uscourts.gov"
  end

  def accept?(download)
    download.request_uri == "http://www.ilcd.uscourts.gov/ordersopinions.htm"
  end

  def request
    DownloadRequest.new("http://www.ilcd.uscourts.gov/ordersopinions.htm")
  end 

  def date_convert(date)
	month = date.match(/\w+/)[0]
	day = date.match(/\d+/)[0]
	year = date.match(/\d{4}/)[0]
	if day.length == 1
		tem = day
		day = "0" 
		day << tem
	end

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
	answer = ""
	answer << year << "-" << month << "-" << day
  end

  def parse(download, receiver)
    doc = Hpricot(download.response_body_as('US-ASCII'))

    unless table = doc.at("table[@height='1875']").at("td[@width='321']").at("table[@width='294']")
      raise Exception.new("Unable to find main table")
    end

    rows = table.search("tr")
    rows.shift

    rows.each do |x|
        if x.inner_html =~ /.+a href.+/        
		
		if x.search("td[@width='278']")[0]
			column = x.search("td[@width='278]'")[0]
		elsif x.search("td[@width='276']")[0]
			column = x.search("td[@width='276']")[0]
		end
		unless column.at("font[@color='#000000']")
			entry = Document.new
			unless entry.dockets << column.inner_text.match(/\d{2}-\w{2}-\d{4,5}/)[0]
				entry.dockets << column.at("font[@class='style1']").at("span").inner_text.strip
			end
			name = (column.search("a").inner_text.gsub(/(\r\n\s+)|(Case)/, "").gsub(/\d{2}-\w{2}-\d{4,5}/, "").match(/\w.*\w/))[0].gsub(/\?/, "").strip
			if name[0] == 97 && name[1] == 110 && name[2] == 100 && name[3] == 32
				entry.name = name[4..-1]
			else
				entry.name = name
			end
			entry.opinion_by = (column.inner_text.match(/Judge\s*.+\s*Entered/)[0]).gsub(/Judge/, "").gsub(/Entered/, "").strip
			date = (column.inner_text.match(/docket\s*\w+\s\d{1,2},\s\d{4}/)[0])[7..-1]
			entry.date = date_convert(date)
			link = "http://www.ilcd.uscourts.gov/" 
			link << column.at("a").attributes['href']
			entry.add_link("pdf", link)
			receiver << entry
		end
	end
     end
    
  end

end
