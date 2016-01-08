module Questionable
  class Comic
    include Celluloid

    def initialize(title, url)
      @title = title
      @url = url
      @future = future.fetch
    end
    attr_reader :title, :url

    def images
      @future.value
    end

    def fetch
      parse(page)
    end

    def parse(html)
      images = html.search("//img[@src*=comics/]")
      images << html.search("//img[@src*=#{Time.now.year}/#{@url.split('//')[1].split('.').first}]")
      images << html.search("//img[@src*=/comics/]")
      images << html.search('#comic > img')

      images.flatten.uniq.map do |image|
        next if image[:src] =~ /(facebook|twitter).gif/

        if image[:src] !~ %r{\A(http:)?//}
          image[:src] = [@url, image[:src]].join("/").gsub('///', '//').
                        gsub("#{@url}#{@url}", @url).
                        gsub("#{@url}//", "#{@url}/")
        end

        # ensure // links are http:// instead.
        image[:src] = image[:src].gsub(%r{\A//}, 'http://')

        image
      end.compact
    end

    def page
      uri = URI.parse(@url)
      resp = Net::HTTP.get_response(uri)
      if resp.class.name == "Net::HTTPFound" && resp.inspect =~ /302/
        resp = Net::HTTP.get_response(URI.parse("#{@url.gsub('/comics/', resp['location'])}"))
      end
      Hpricot(resp.body)
    end

    def haml_object_ref
      "comic"
    end

    def id
      @title
    end
  end
end
