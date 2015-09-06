require 'open3'

module Zio
  class Branch
    attr_accessor :options
    def initialize(options = {})
      @options = options
      raise MISSING_ARGUMENTS unless options[:dir] || options[:set]
    end

    def checkout
      _paths.each do |path|
        puts sprintf("\nProcessing - #{path}").color(:green)
        puts sprintf('---------------------------').color(:green)
        stdout, stderr, status = Open3.capture3("cd #{path} && git stash && git rev-parse --verify #{options[:branch]}")

        # Branch does not exists
        if status.exitstatus != 0
          puts("Branch #{branch} does not exists yet!").color(:blue)
          if options[:force]
            puts("Creating new branch - #{branch}").color(:blue)
            stdout, stderr, status = Open3.capture3(
              "cd #{path} && git checkout #{options[:base_branch]} && git checkout -b #{options[:branch]}"
            )
            puts stdout.color(:blue)
          end
        else
          stdout, stderr, status = Open3.capture3("cd #{path} && git checkout #{options[:branch]}")
          puts sprintf("%s%s", stderr.color(:red), stdout.color(:blue))
        end
      end
    end

    def _paths
      return options[:set] unless options[:set].nil?
      @_paths ||= begin
        Dir.foreach(options[:dir]).map do |path|
          next if path == '.' || path == '..' || !File.exist?(File.expand_path(path, options[:dir]) + '/.git')
          ab_path = File.expand_path(path, options[:dir])
          File.directory?(ab_path) ? ab_path : nil
        end.compact
      end
    end
  end
end
