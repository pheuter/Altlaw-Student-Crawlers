class Azd
  include Expect
  
  def accept_host
    "www.azd.uscourts.gov"
  end
  
  def accept?(download)
    download.reqest_uri == "http://www.azd.uscourts.gov/azd/courtopinions.nsf/Opinions%20by%20number?OpenView"
  end
  
  def request
    DownloadRequest.new("http://www.azd.uscourts.gov/azd/courtopinions.nsf/Opinions%20by%20number?OpenView")
  end
  
  def parse(download,receiver)
    html = download.response_body_as('US-ASCII')
    doc = Hpricot(html)
    
    unless table = doc.at("table[@width='100%']").at("td[@width='50%]").at("table[@cellpadding='2']")
      raise Exception.new("Unable to find main table")
    end
    
    rows = table.search("tr")
    
    first_row = rows.shift

    date_posted_heading = first_row.at("th[1]").inner_text
    match(date_posted_heading, "Case No.")
    
    rows.each do |row|
      document = Document.new
      date_string = row.at("td[5]").inner_text
      date_string =~ %r{(\d{1,2})/(\d{1,2})/(\d{4})}
      date = Date.new($3.to_i, $1.to_i, $2.to_i)
      document.date = date
      
      document.name = row.at("td[3]").inner_text
      document.dockets << row.at("td[1]").inner_text
      
      link = "http://www.azd.uscourts.gov" + row.at("td[7] a").attributes['href']
      document.add_link("applications/pdf", link)
      
      document.court = "http://id.altlaw.org/courts/us/fed/dist/azd"
      receiver << document
    end
  end
end