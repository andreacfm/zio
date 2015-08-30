require 'celluloid/current'
require 'open3'
require 'rainbow/ext/string'

module Zio
  class UpLogger
    include Celluloid
    include Celluloid::Notifications
    attr_accessor :out, :last

    def initialize
      subscribe 'up_last_path', :last_path
      subscribe 'up_capture_complete', :new_data
      @out = []
    end

    def new_data(_topic, data)
      puts data
      @out << data
    end

    def last_path(_topic, data)
      puts data
      @last = data
    end

    def print
      current_path = 'path'
      while last != current_path do
        next if out.empty?
        data = out.shift
        path, stdout, stderr, status = *data
        dirname = path.split('/').last
        puts sprintf("\nProcessing - #{dirname}").color(:green)
        puts sprintf('---------------------------').color(:green)
        if status.exitstatus == 0
          puts sprintf('[%s] - %s', dirname, stdout).color(:blue)
        else
          STDERR.puts stderr.color(:red)
        end
        current_path = path
      end
    end
  end

  class Up
    attr_accessor :dir
    include Celluloid
    include Celluloid::Notifications

    # Celluloid.logger = nil

    def initialize(dir)
      @dir = dir
    end

    def up
      publish 'up_last_path', _paths.last
      _paths.each do |path|
        #Celluloid::Future.new { _pull(path) }
        # future.value
        #self.class.pool(size: 8, args: dir).future._pull(path)
        #_pull(path)
        self.future._pull(path)
      end
    end

    def _pull(path)
      stdout, stderr, status = Open3.capture3("cd #{path} && git stash && git checkout master && git pull --rebase")
      Celluloid::Notifications.publish 'up_capture_complete', [path, stdout, stderr, status]
    end

    def _paths
      @_paths ||= begin
        Dir.foreach(dir).map do |path|
          next if path == '.' || path == '..'
          ab_path = File.expand_path(path, dir)
          File.directory?(ab_path) ? ab_path : nil
        end.compact
      end
    end
  end
end
