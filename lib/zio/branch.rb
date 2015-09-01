require 'open3'

module Zio
  class Branch
    attr_accessor :options
    def initialize(options={})
      @options = options
      raise MISSING_ARGUMENTS unless options[:dir] || options[:set]
    end

    def checkout
      _paths.each do |path|
        #self.class.new(options).async.pull(path)
        puts path
        stdout, stderr, status = Open3.capture3("cd #{path} && git stash && git rev-parse --verify #{options[:branch]}")

        # Branch does not exists
        if status.exitstatus != 0 && options[:force]
          stdout, stderr, status = Open3.capture3(
              "cd #{path} && git checkout #{options[:base_branch]} && git checkout -b #{options[:branch]}"
          )
        else
          stdout, stderr, status = Open3.capture3("cd #{path} && git checkout #{options[:branch]}")
        end
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
