require 'celluloid/current'
require 'open3'
require 'rainbow/ext/string'

module Zio
  class UpLogger
    include Celluloid
    include Celluloid::Notifications
    attr_accessor :out, :paths

    def initialize
      subscribe 'up_paths', :set_paths
      subscribe 'up_capture_complete', :new_data
      @out = []
      @paths = [1]
    end

    def new_data(_topic, data)
      @out << data
    end

    def set_paths(_topic, data)
      @paths.concat(data)
    end

    def print
      while paths.size > 0 do
        if out.empty?
          sleep 2
          next
        end
        data = out.shift
        path, stdout, stderr, status = *data
        puts sprintf("\nProcessing - #{path}").color(:green)
        puts sprintf('---------------------------').color(:green)
        if status.exitstatus == 0
          puts sprintf('[%s] - %s', path, stdout).color(:blue)
        else
          STDERR.puts stderr.color(:red)
        end
        paths.delete(path)
        paths.delete(1) if paths.size == 1 && paths[0] == 1
      end
    end
  end

  class Up
    attr_accessor :options
    include Celluloid
    include Celluloid::Notifications

    # Celluloid.logger = nil

    def initialize(options={})
      @options = options
      raise MISSING_ARGUMENTS unless options[:dir] || options[:set]
    end

    def up
      publish 'up_paths', _paths
      _paths.each do |path|
        self.class.new(options).async.pull(path)
      end
    end

    def pull(path)
      stdout, stderr, status = Open3.capture3("cd #{path} && git stash && git checkout master && git pull --rebase")
      publish 'up_capture_complete', [path, stdout, stderr, status]
    end

    def _paths
      return options[:set] unless options[:set].nil?
      @_paths ||= begin
        Dir.foreach(options[:dir]).map do |path|
          next if path == '.' || path == '..' || !File.exists?(File.expand_path(path, options[:dir]) + '/.git')
          ab_path = File.expand_path(path, options[:dir])
          File.directory?(ab_path) ? ab_path : nil
        end.compact
      end
    end
  end
end
