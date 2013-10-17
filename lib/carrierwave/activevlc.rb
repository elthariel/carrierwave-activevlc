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
        process pipeline: ::ActiveVlc::Pipeline.new(&block)
      end
    end


    def pipeline(pipe)
      # move upload to local cache
      cache_stored_file! if !cached?

      # The tmpfile should keep the same extension because some vlc modules
      # rely on it to detect the type of the file.
      directory = File.dirname current_path
      basename  = File.basename current_path
      my_tmp_path  = File.join(directory, "tmp-#{rand 9999}-#{basename}")

      Dir.mkdir directory unless Dir.exists? directory
      File.rename current_path, my_tmp_path

      pipe.input.clear! # Reset input of previous run
      pipe.input << my_tmp_path
      pipe.params output: current_path

      ::ActiveVlc::Runner.new(pipe, '-vvv').run(type: :exec, vlc_path: ENV['VLC_PATH'])

      if File.exists?(my_tmp_path) and File.size(my_tmp_path) > 42
        File.delete(my_tmp_path)
        File.rename(current_path, my_tmp_path)
        avconv_path = ENV['AVCONV_PATH'] ? ENV['AVCONV'] : 'avconv'
        `#{avconv_path} -i #{my_tmp_path} -acodec copy -vcodec copy #{current_path}`
        File.delete(my_tmp_path)
      else
        File.rename(my_tmp_path, current_path)
      end
    end
  end
end
