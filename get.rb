#!/usr/bin/env ruby
require 'net/http'
require 'rubygems'
require 'hpricot'

comics = []
urls = []
# add urls in the format:
# urls << ["Title", "http://site.com"]
urls.each do |title, url|
 begin
    uri = ::URI.parse(url)
    resp = ::Net::HTTP.get_response(uri)
    if resp.class.name == "Net::HTTPFound" and resp.inspect =~ /302/
      resp = ::Net::HTTP.get_response(URI.parse("#{url.gsub('/comics/', resp['location'])}"))
    end
    html = Hpricot(resp.body)
    images = html.search("//img[@src*=comics/]")
    images << html.search("//img[@src*=#{Time.now.year}/#{url.split('//')[1].split('.').first}]")
    images << html.search("//img[@src*=db/files/Comics/]")

    images = images.sort_by { |i, j| i.to_s <=> j.to_s } if images.size > 1
    comics << "<div id='#{title}'>"
    comics << images.flatten.collect do |i|
      if i.to_s =~ /http:\/\//
        i.to_s
      else
        i.to_s.gsub(/src=[\"|\']/){|m| "#{m}#{url}/"}.gsub("#{url}#{url}", url).gsub("#{url}//", "#{url}/")
      end
    end
    comics << "</div>"
  rescue
    puts "can't get #{url}"
  end
end
dir = File.dirname(__FILE__)
File.delete(File.join(dir, "latest.html")) if File.exists?(File.join(dir, "latest.html"))
titles = urls.collect{|t,u| "<a href='##{t}'>#{t}</a>"}
File.open(File.join(dir, "latest.html"), "w").puts(
  "<html><head><link rel='stylesheet' href='ui.css'/><script src='jquery-min.js'></script><script src='jquery-ui-custom-min.js'></script>
   <script>$(document).ready(function(){$('#tabs').tabs({tabTemplate: '<li><a href=\"\#{href}\">\#{label}</a></li>'})});</script>
   </head><body><div id='tabs'>\n<ul id='nav'><li>#{titles.join('</li><li>')}</li></ul>#{comics.flatten.join("\n")}\n</div></body></html>"
) unless comics.empty?

`open #{File.join(dir, "latest.html")}`