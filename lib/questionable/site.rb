module Questionable
  class Site
    def initialize(title, url)
      @title = title
      @url = url
    end
    attr_reader :title, :url
  end
end
