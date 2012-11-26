#!/usr/bin/env ruby
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'fileutils'
require 'pathname'
require 'yaml'
require 'peach'

comics = []
unless (config_file = Pathname.new(File.expand_path('../config.yml', __FILE__))).exist?
  FileUtils::cp "#{config_file}.example", config_file.to_s
end
(urls = YAML::load(config_file.read)['urls']).peach do |c|
 begin
    uri = ::URI.parse((url = c['url']))
    resp = ::Net::HTTP.get_response(uri)
    if resp.class.name == "Net::HTTPFound" and resp.inspect =~ /302/
      resp = ::Net::HTTP.get_response(URI.parse("#{url.gsub('/comics/', resp['location'])}"))
    end
    html = Hpricot(resp.body)
    images = html.search("//img[@src*=comics/]")
    images << html.search("//img[@src*=#{Time.now.year}/#{url.split('//')[1].split('.').first}]")
    images << html.search("//img[@src*=db/files/Comics/]")

    images = images.sort_by { |i, j| i.to_s <=> j.to_s } if images.size > 1
    comics << "<div id='#{c['title']}'>"
    comics << images.flatten.collect do |i|
      if i.to_s =~ /http:\/\//
        image = i.to_s
      else
        image = i.to_s.gsub(/src=[\"|\']/){|m| "#{m}#{url}/"}.gsub("#{url}#{url}", url).gsub("#{url}//", "#{url}/")
      end

      "#{image}<br/>"
    end
    comics << "</div>"
  rescue
    puts "can't get #{url}"
  end
end
dir = File.dirname(__FILE__)
File.delete(File.join(dir, "latest.html")) if File.exists?(File.join(dir, "latest.html"))
unless comics.empty?
  titles = urls.collect{|h| "<a href='##{h['title']}'>#{h['title']}</a>"}
  File.open(File.join(dir, "latest.html"), "w").puts(
    "<html><head><link rel='stylesheet' href='ui.css'/><script src='jquery-min.js'></script><script src='jquery-ui-custom-min.js'></script>
     <script>$(document).ready(function(){$('#tabs').tabs({tabTemplate: '<li><a href=\"\#{href}\">\#{label}</a></li>'})});</script>
     </head><body><div id='tabs'>\n<ul id='nav' class='clearfix'><li>#{titles.join('</li><li>')}</li></ul><br/>#{comics.flatten.join("\n")}\n</div></body></html>"
  )

  `open #{File.join(dir, "latest.html")}`
else
  $stdout.puts "Nothing found, sorry."
end
