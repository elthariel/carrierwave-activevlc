require "carrierwave/activevlc/version"
require "activevlc"
require "carrierwave"

module CarrierWave
  module ActiveVlc
    extend ActiveSupport::Concern

    module ClassMethods
      #
      # Encode the video using the Pipeline described in the provided block
      # The block _MUST_ have a file output configured to param(:output)
      #
      def encode_video(&block)
        return unless block_given?
        pipeline = ::ActiveVlc::Pipeline.new &block
        process pipeline: [pipeline]
      end
    end


    def pipeline(pipe)
      # move upload to local cache
      cache_stored_file! if !cached?

      # The tmpfile should keep the same extension because some vlc modules
      # rely on it to detect the type of the file.
      directory = File.dirname current_path
      basename  = File.basename current_path
      tmp_path  = File.join(directory, "tmp-#{rand 9999}-#{basename}")

      Dir.mkdir directory unless Dir.exists? directory
      File.rename current_path, tmp_path

      pipe.input << tmp_path
      pipe.params output: current_path

      ::ActiveVlc::Runner.new(pipe, '-vvv').run(true)

      if File.exists?(tmp_path) and File.size(tmp_path) > 42
        File.delete(tmp_path)
      else
        File.rename(tmp_path, current_path)
      end
    end
  end
end
