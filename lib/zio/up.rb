require 'celluloid'
require 'open3'
require 'rainbow/ext/string'

module Zio
  class Up
    attr_accessor :dir
    include Celluloid
    Celluloid.logger = nil

    def initialize(dir)
      @dir = dir
    end

    def up
      _paths.each do |path|
        #future = Celluloid::Future.new { _async_pull(path) }
        #future.value
        self.class.pool(size: 8, args: dir).future._async_pull(path)
        #_async_pull(path)
      end
    end

    def _async_pull(path)
      dirname = path.split('/').last
      stdout, stderr, status = Open3.capture3("cd #{path} && git stash && git checkout master && git pull --rebase")
      puts sprintf("\nProcessing - #{dirname}").color(:green)
      puts sprintf("---------------------------").color(:green)
      if status.exitstatus == 0
        puts sprintf("[%s] - %s", dirname, stdout).color(:blue)
      else
        STDERR.puts stderr.color(:red)
      end
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