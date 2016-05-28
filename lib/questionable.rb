require 'net/http'
require 'hpricot'
require 'fileutils'
require 'pathname'
require 'yaml'
require 'celluloid/current'
require 'haml'

require 'questionable/fetcher'
require 'questionable/comic'

module Questionable
  def self.fetch(config_filename, output_filename, last_run)
    Fetcher.new(config_filename, output_filename, last_run).run
  end
end
