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
      futures = comics.map do |comic|
        comic.future(:fetch)
      end
      futures.each(&:value)
      @output_filename.delete if @output_filename.exist?
      unless comics.empty?
        options = {
          format: :html5
        }
        engine = Haml::Engine.new(File.read(File.expand_path("../../../views/index.html.haml", __FILE__)), options)

        @output_filename.open("w").puts engine.render(nil, comics: comics)

        `open #{@output_filename}`
      else
        $stdout.puts "Nothing found, sorry."
      end
    end
  end
end
