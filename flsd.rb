class Flsd
  include Expect  # always include this

  OPINIONS_PAGE = "http://www.flsd.uscourts.gov/default.asp?file=cases/pressDocs.asp"

  def accept_host
    "www.flsd.uscourts.gov"
  end

  def accept?(download)
    download.request_uri == OPINIONS_PAGE
  end

  def request
    DownloadRequest.new(OPINIONS_PAGE)
  end

  def parse(download, receiver)
    doc = Hpricot(download.response_body_as('US-ASCII'))
    cases =  doc.search("table/tr/td[@align='left']")
    cases.each do |c|
      document = nil
      new_doc = true
      info = c.at("font b i").inner_html
      docket = info.split.first
      receiver.each do |a_doc|
        a_doc.dockets.each do |a_docket|
          if a_docket == docket
            document = a_doc
            new_doc = false
          end
        end
      end
      
      if new_doc
        document = Document.new
        document.dockets << docket
        doc_name = ""
        info.reverse.split('').each do |char|
          break if char == '-'
          doc_name << char
        end
        document.name = doc_name.reverse.strip
#        c.inner_html =~ /\((\d{2})\/(\d{2})\/(\d{4})\)/
        md = match(c.inner_html,/\((\d{2})\/(\d{2})\/(\d{4})\)/)
        document.date = Date.new(md[3].to_i, md[1].to_i, md[2].to_i)
        document.court = 'http://id.altlaw.org/courts/us/fed/dist/flsd'
      end

      anchor_tag = c.at("a")
      raise "could not find anchor tag" unless anchor_tag
      pdf_js = anchor_tag['onclick']
      if (md = match(pdf_js,/file=(.*)\.pdf/))
        document.add_link("application/pdf","www.flsd.uscourts.gov" + md[1] + '.pdf')
      else
        raise Exception.new("could not find pdf name")
      end

      receiver << document if new_doc
    end
  end
end
