#designed to work for any court_web state. This version implemented for Connecticut
require 'enumerator'

class Court_Web
  include Expect
  
  def accept_host
    "http://www.nysd.uscourts.gov/courtweb/public.htm"
  end
  
  def accept?(download)
    download.request_uri == "http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=1%2F1%2F09&end=12%2F31%2F09&outtype=" or
      download.request_uri == "http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=1%2F1%2F08&end=6%2F1%2F08&outtype=" or
        download.request_uri == "http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=6%2F1%2F08&end=12%2F31%2F08&outtype=" or
          download.request_uri == "http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=1%2F1%2F07&end=6%2F1%2F07&outtype=" or
            download.request_uri == "http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=6%2F1%2F07&end=12%2F31%2F07&outtype=" or
              download.request_uri == "http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=5%2F1%2F06&end=12%2F31%2F06&outtype="
  end
  
  def request
    [DownloadRequest.new("http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=1%2F1%2F09&end=12%2F31%2F09&outtype="),
      DownloadRequest.new("http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=1%2F1%2F08&end=6%2F1%2F08&outtype="),
      DownloadRequest.new("http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=6%2F1%2F08&end=12%2F31%2F08&outtype="),
      DownloadRequest.new("http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=1%2F1%2F07&end=6%2F1%2F07&outtype="),
      DownloadRequest.new("http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=6%2F1%2F07&end=12%2F31%2F07&outtype="),
      DownloadRequest.new("http://www.nysd.uscourts.gov/cwrulings.fwx?mode=rptexec&cascode=D02CTXC&watchdate=&judge=&caseyr=++&casetp=&caseno=&capsrch=&descsrch=&start=5%2F1%2F06&end=12%2F31%2F06&outtype=")
    ]
  end
  
  def parse(download, receiver)
    html = download.response_body_as('US-ASCII')
    doc = Hpricot(html)
    
    unless table = doc.at("table")
      raise Exception.new("Unable to find main table.")
    end
    
    rows = table.search("tr")
    first_row = rows[0]
    
    match(first_row.at("th[1]").inner_text, "Date")
    match(first_row.at("th[2]").inner_text, "Case #")
    match(first_row.at("th[3]").inner_text, "Caption")
    match(first_row.at("th[4]").inner_text, "Title")
    match(first_row.at("th[5]").inner_text, "Judge")
    match(first_row.at("th[6]").inner_text, "Posted")
    
    rows = rows.enum_for(:each_slice, 5).to_a    
    rows.each do |row|
      document = Document.new
      date_string = row[1].at("td[6]").inner_text
      date_string =~ %r{(\d{1,2})/(\d{1,2})/(\d{1,2})}
      document.date = Date.new("20#{$3}".to_i,$1.to_i,$2.to_i)

      name = row[1].at("td[3]").inner_text
      name =~ /(.+\S)/
      document.name = $1

      opinion = row[1].at("td[5]").inner_text
      opinion =~ /(.+\S)/
      document.opinion_by = $1

      description = row[3].inner_text
      description =~ /(.+\S)/
      document.description = $1
      
      document.dockets << row[1].at("td[2]").inner_text

      if row[4].at("a") != nil
        link = "http://www.nysd.uscourts.gov" + row[4].at("a").attributes['href']
        document.add_link("applications/pdf", link)
      end
      
      document.court = "http://id.altlaw.org/courts/us/fed/dist/ctd"
      receiver << document
    end
  end
end