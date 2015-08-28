require 'celluloid'

module Zio
  class Up
    attr_accessor :dir
    include Celluloid

    def initialize(dir)
      @dir = dir
    end

    def up
      _paths.each do |path|
        self.class.pool(size: 5, args: [dir]).future._async_pull(path)
      end
    end

    def _async_pull(path)
      puts "Pulling #{path}"
      system "cd #{path} && git smart-pull"
    end

    def _paths
      Dir.foreach(dir).map do |path|
        next if path == '.' || path == '..'
        ab_path = File.expand_path(path, dir)
        File.directory?(ab_path) ? ab_path : nil
      end.compact
    end

  end
end