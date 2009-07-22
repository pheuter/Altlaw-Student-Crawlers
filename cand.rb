class Cand
  include Expect
  
  def accept_host
    "www.cand.uscourts.gov"
  end
  
  def accept?(download)
    download.request_uri == "http://www.cand.uscourts.gov/cand/judges.nsf/61fffe74f99516d088256d480060b72d?OpenView"
  end
  
  def request
    DownloadRequest.new("http://www.cand.uscourts.gov/cand/judges.nsf/61fffe74f99516d088256d480060b72d?OpenView")
  end
  
  def parse(download,receiver)
    html = download.response_body_as('US-ASCII')
    
    doc = Hpricot(html)
    unless table = doc.at("table").at("td[@width='502]").at("table[@cellpadding='2']")
      raise Exception.new("Unable to load main table")
    end
    
    rows = table.search("tr")
    
    first_row = rows.shift
    
    date_posted_heading = first_row.at("th[2]").inner_text
    match(date_posted_heading, "Filing Date")
    
    rows.each do |row|
      document = Document.new
      
      if row.at("td[2]").inner_text != ""
        date_string = row.at("td[2]").inner_text 
        date_string =~ %r{(\d{1,2})/(\d{1,2})/(\d{4})}
        document.date = Date.new($3.to_i, $1.to_i, $2.to_i)
      end
      
      document.opinion_by = row.at("td[5]").inner_text
      document.name = row.at("td[4]").inner_text
      document.dockets << row.at("td[3]").inner_text
      
      link = "http://www.cand.uscourts.gov" + row.at("td[4] a").attributes['href']      
      document.add_link("text/html", link)
      
      document.court = "http://id.altlaw.org/courts/us/fed/dist/cand"
      receiver << document
    end
  end
end