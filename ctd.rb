class Ctd
  include Expect
  
  def accept_host
    "www.ctd.uscourts.gov"
  end
  
  def accept?(download)
    download.request_uri == "http://www.ctd.uscourts.gov/cv_opinions.html" or
      download.request_uri == "http://www.ctd.uscourts.gov/cr_opinions.html"
  end
  
  def request
    [DownloadRequest.new("http://www.ctd.uscourts.gov/cv_opinions.html"),DownloadRequest.new("http://www.ctd.uscourts.gov/cr_opinions.html")]
  end
  
  def parse(download,receiver)
    html = download.response_body_as('UTF-8')
    
    doc = Hpricot(html)
    unless table = doc.search("table").last
      raise Exception.new("Could not find main table")
    end
    
    rows = table.search("tr")  
    first_row = rows.shift
    
    match(first_row.at("td[1]").inner_text,"DATE")
    match(first_row.at("td[2]").inner_text,"JUDGE")
    match(first_row.at("td[4]").inner_text,"TOPICS DISCUSSED")
    
    rows.each do |row|
      document = Document.new
      date_string = row.at("td[1]").inner_text
      if date_string =~ /([1-9]+)\/(\d{1,2})\/(\d{4})/
        document.date = Date.new($3.to_i, $1.to_i, $2.to_i)
      end
      
      name = row.at("td[3] a")
      if name != nil and name.inner_text =~ /[A-Z].+/
        document.name = name.inner_text.scan(/[A-Z].+/).join(" ").delete("\r")
      end
      
      docket = row.at("td[3] b")
      if docket != nil and docket.children != nil and docket.children.last.inner_text =~ /(\d:\w+)/
        document.dockets << $1
      end

      link = row.at("td[3] a")
      if link != nil and link.attributes['href'] =~ /(O{1}.+.pdf)/
        document.add_link("applications/pdf", "www.ctd.uscourts.gov/#{$1}")
      end
      
      opinion = row.at("td[2]")
      if opinion != nil and opinion.inner_text =~ /[A-Z].+/
        document.opinion_by = opinion.inner_text.scan(/[A-Z].+/).join(" ").delete("\r")
      end
      
      if download.request_uri == "http://www.ctd.uscourts.gov/cv_opinions.html"
        document.opinion_type = "Civil"
      else
        document.opinion_type = "Criminal"
      end
            
      document.court = "http://id.altlaw.org/courts/us/fed/dist/ctd"
      receiver << document
    end
  end
end