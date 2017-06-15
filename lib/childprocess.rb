require 'childprocess/version'
require 'childprocess/errors'
require 'childprocess/abstract_process'
require 'childprocess/abstract_io'
require "fcntl"
require 'logger'

module ChildProcess

  @posix_spawn = false

  class << self
    attr_writer :logger

    def logger
      return @logger if defined?(@logger) and @logger

      @logger = Logger.new($stderr)
      @logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO

      @logger
    end

    def platform
      if RUBY_PLATFORM == "java"
        :jruby
      elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == "ironruby"
        :ironruby
      else
        os
      end
    end

    def platform_name
      @platform_name ||= "#{arch}-#{os}"
    end

    def unix?
      !windows?
    end

    def linux?
      os == :linux
    end

    def jruby?
      platform == :jruby
    end

    def windows?
      os == :windows
    end

    def os
      @os ||= (
        require "rbconfig"
        host_os = RbConfig::CONFIG['host_os'].downcase

        case host_os
        when /linux/
          :linux
        when /darwin|mac os/
          :macosx
        when /mswin|msys|mingw32/
          :windows
        when /cygwin/
          :cygwin
        when /solaris|sunos/
          :solaris
        when /bsd/
          :bsd
        when /aix/
          :aix
        else
          raise Error, "unknown os: #{host_os.inspect}"
        end
      )
    end

    def arch
      @arch ||= RbConfig::CONFIG['host_cpu']
    end

    def new(*args)
      RubySpawnProcess.new(args)
    end
    alias_method :build, :new

    #
    # By default, a child process will inherit open file descriptors from the
    # parent process. This helper provides a cross-platform way of making sure
    # that doesn't happen for the given file/io.
    #

    def close_on_exec(file)
      file.close_on_exec = true
    end

  end # class << self
end # ChildProcess

require 'childprocess/ruby_spawn_process'
