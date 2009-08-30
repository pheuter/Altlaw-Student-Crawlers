class Insd
  include Expect  # always include this

  OPINIONS_PAGE = "http://www.insd.uscourts.gov/News/recent_opinions.htm"

  def accept_host
    "www.insd.uscourts.gov"
  end

  def accept?(download)
    download.request_uri == OPINIONS_PAGE
  end

  def request
    DownloadRequest.new(OPINIONS_PAGE)
  end

  def parse(download, receiver)
    doc = Hpricot(download.response_body_as('US-ASCII'))
    current_judge = "NO JUDGE"
    doc.search('tr').each do |tr|
      if (anchor = tr.at('td/b/font/a'))
        current_judge = anchor.inner_text
        next
      end
      tr.search('td').each do |td|
        next if current_judge == "NO JUDGE"
        anchor = td.at('strong/font/a')
        anchor = td.at('font/a') unless anchor #...was already not nil
        anchor = td.at('a') unless anchor
        if anchor
          document = Document.new
          document.court = "http://id.altlaw.org/courts/us/fed/dist/insd"
          document.opinion_by = current_judge.delete("\t\n\r?").strip
          document.name = anchor.inner_text.delete("\t\n\r?").strip
          #puts 'anchor.inner_text = ' + anchor.inner_text
          #puts 'anchor[href] = ' + anchor['href']
          pdf_name = /[Oo]pinions\/(.*\.(pdf|PDF))/.match(anchor['href'])[1]
          pdf_full_name = 'www.insd.uscourts.gov/Opinions/' + pdf_name
          document.add_link('application/pdf',pdf_full_name)

          #puts 'td.inner_text = ' + td.inner_text
          md = /Cause No\. ((.|\s)*?)(\d{1,2})\/(\d{1,2})\/(\d{2})/.match(td.inner_text)
          document.dockets << md[1].delete("\t\n\r?").strip
          #md = /(\d{1,2})\/(\d{1,2})\/(\d{2})/.match(td.inner_text)
          begin
            document.date = Date.new(('20' + md[5]).to_i,md[3].to_i,md[4].to_i)
          rescue ArgumentError => err
            puts 'date \'' + md[3] + '/' + md[4] + '/' + md[5] + '\' caused an argument error: ' + err.to_s + '; skipping case "' + document.name + '"'
            next
          end
          receiver << document
        end
      end
    end
  end
end
