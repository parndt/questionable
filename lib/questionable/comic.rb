module Questionable
  class Comic
    def initialize(title, url)
      @title = title
      @url = url
    end
    attr_reader :title, :url
    attr_accessor :images
  end
end
