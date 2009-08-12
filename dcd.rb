class Dcd
  include Expect  # always include this

  def accept_host
    "www.dcd.uscourts.gov"
  end

  def accept?(download)
    download.request_uri == "https://ecf.dcd.uscourts.gov/cgi-bin/Opinions.pl"
  end

  def request
    DownloadRequest.new("https://ecf.dcd.uscourts.gov/cgi-bin/Opinions.pl")
  end

  def parse(download, receiver)
    doc = Hpricot(download.response_body_as('US-ASCII'))
    table = doc.at('table#ts')
    raise Exception.new("opinions table not found") unless table
    header_anchors = table.search('th a')
    match(header_anchors[0].inner_html,"Date Filed")
    match(header_anchors[1].inner_html,"Case")
    match(header_anchors[2].inner_html,"Opinion")
    table.search('/tbody/tr').each do |row|
      document = Document.new
      document.court = "http://id.altlaw.org/courts/us/fed/dist/dcd"

      date_text = row.at('td[1]').inner_html
      date_text =~ /(\d{2})\/(\d{2})\/(\d{4})<!--(.*)-->/
      document.date = Date.new($3.to_i, $1.to_i, $2.to_i)
      number_text = row.at('td[2]').children.first.to_s
      number_text =~ /(\d{4}-\d{4})/
      document.dockets << $1
      document.name = row.at('td[2] br').next.to_s
      row.search('td[3] a').each do |anchor|
        document.add_link('application/pdf', 'https://ecf.dcd.uscourts.gov/cgi-bin/' + anchor['href'])
      end
      judge_text = row.at('td[3] br').next.to_s
      judge_text =~ /by (.*)/
      document.opinion_by = $1

      receiver << document
    end  
  end
end
