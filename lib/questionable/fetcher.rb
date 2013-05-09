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
      comics.pmap(&:fetch)
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
