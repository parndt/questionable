module Questionable
  class Fetcher
    include Celluloid

    def initialize(config_filename, output_filename, last_run)
      @config_filename = config_filename
      @output_filename = output_filename
      @last_run = last_run
    end

    def run
      unless @config_filename.exist?
        FileUtils.cp "#{@config_filename}.example", @config_filename.to_s
      end
      @output_filename.delete if @output_filename.exist?

      if new_comics.any?
        template = File.read(File.expand_path("../../../views/index.html.haml", __FILE__))
        engine = Haml::Engine.new(template, format: :html5)

        @output_filename.open("w").puts engine.render(self)

        comics_with_images = {
          comics: comics.map { |comic|
            { id: comic.id, images: comic.images.map { |image| image[:src] }.uniq }
          }
        }.to_yaml
        @last_run.delete if @last_run.exist?
        @last_run.open("w").puts comics_with_images

        `open -a Safari.app #{@output_filename}`
      else
        $stdout.puts "❌  Nothing new found, sorry."
      end
    end

    def comics
      @comics ||= YAML.load(@config_filename.read)['urls'].map do |h|
        Comic.new(h['title'], h['url'])
      end
    end

    def new_comics
      comics.reject do |comic|
        comic.images.all? do |image|
          last_comic = last_run_comics.detect { |last_run_comic| last_run_comic[:id] == comic.id }
          last_comic && last_comic[:images].include?(image[:src])
        end
      end
    end

    def last_run_comics
      if @last_run.file?
        YAML.load(@last_run.read)[:comics]
      else
        []
      end
    end
  end
end
