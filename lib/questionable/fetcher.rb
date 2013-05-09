#!/usr/bin/env ruby
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'fileutils'
require 'pathname'
require 'yaml'
require 'peach'

module Questionable
  class Fetcher
    def initialize(config_filename, output_filename)
      @config_filename = config_filename
      @output_filename = output_filename
    end

    def run
      comics = {}
      unless @config_filename.exist?
        FileUtils::cp "#{@config_filename}.example", @config_filename.to_s
      end
      comics = YAML::load(@config_filename.read)['urls'].map do |h|
        Comic.new(h['title'], h['url'])
      end
      comics.peach do |comic|
        begin
          uri = ::URI.parse(comic.url)
          resp = ::Net::HTTP.get_response(uri)
          if resp.class.name == "Net::HTTPFound" && resp.inspect =~ /302/
            resp = ::Net::HTTP.get_response(URI.parse("#{comic.url.gsub('/comics/', resp['location'])}"))
          end
          html = Hpricot(resp.body)
          images = html.search("//img[@src*=comics/]")
          images << html.search("//img[@src*=#{Time.now.year}/#{comic.url.split('//')[1].split('.').first}]")
          images << html.search("//img[@src*=db/files/Comics/]")

          images = images.sort_by { |i, j| i.to_s <=> j.to_s } if images.size > 1
          comic.images = images.flatten.collect do |i|
            if (image = i.to_s) !~ /http:\/\//
              image = image.gsub(/src=[\"|\']/){|m| "#{m}#{comic.url}/"}.
                            gsub("#{comic.url}#{comic.url}", comic.url).
                            gsub("#{comic.url}//", "#{comic.url}/")
            end

            image
          end
        rescue
          puts "can't get #{comic.url}: #{$!.inspect}"
        end
      end
      @output_filename.delete if @output_filename.exist?
      unless comics.empty?
        titles = comics.collect{|comic| "<a href='##{comic.title}'>#{comic.title}</a>"}
        @output_filename.open("w").puts <<-ENDHTML
<html>
  <head>
    <link rel='stylesheet' href='ui.css'/>
    <script src='jquery-min.js'></script>
    <script src='jquery-ui-custom-min.js'></script>
    <script>
      $(document).ready(function(){
        $('#tabs').tabs({tabTemplate: '<li><a href=\"\#{href}\">\#{label}</a></li>'})
      });
    </script>
  </head>
  <body>
    <div id='tabs'>\n
      <ul id='nav' class='clearfix'>
        <li>#{titles.join('</li><li>')}</li>
      </ul>
      <br/>
      #{comics.map { |comic|
          "<div id='#{comic.title}'>#{comic.images.flatten.join('<br/>')}</div>"
        }.join("\n")
      }\n
    </div>
  </body>
</html>
        ENDHTML

        `open #{@output_filename}`
      else
        $stdout.puts "Nothing found, sorry."
      end
    end
  end
end
