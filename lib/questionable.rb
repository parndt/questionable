require 'questionable/fetcher'
require 'questionable/site'

module Questionable
  def self.fetch(config_filename, output_filename)
    Fetcher.new(config_filename, output_filename).run
  end
end
