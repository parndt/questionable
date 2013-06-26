module Questionable
  class Fetcher
    include Celluloid

    def initialize(config_filename, output_filename)
      @config_filename = config_filename
      @output_filename = output_filename
    end

    def run
      unless @config_filename.exist?
        FileUtils.cp "#{@config_filename}.example", @config_filename.to_s
      end
      @output_filename.delete if @output_filename.exist?

      unless comics.empty?
        template = File.read(File.expand_path("../../../views/index.html.haml", __FILE__))
        engine = Haml::Engine.new(template, format: :html5)

        @output_filename.open("w").puts engine.render(self)

        sleep 0.1

        `open #{@output_filename}`
      else
        $stdout.puts "Nothing found, sorry."
      end
    end

    def comics
      @comics ||= YAML.load(@config_filename.read)['urls'].map do |h|
        Comic.new(h['title'], h['url'])
      end
    end
  end
end
