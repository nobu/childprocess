require 'thread'
require 'childprocess/unix'

module ChildProcess
  class RubySpawnProcess < Unix::Process
    private

    NULL = ::IO::NULL

    def launch_process
      options = {}
      options[:out] = io.stdout || NULL
      options[:err] = io.stderr || NULL
      options[:chdir] = @cwd if @cwd
      options[:pgroup] = true if leader?
      executable, *args = @args
      cmd = [@environment, [executable, executable], *args, options]
      if duplex?
        writer = ::IO.popen(cmd, "w")
        @pid = writer.pid
        io._stdin = writer
      else
        options[:in] = io.stdin || NULL
        @pid = ::Process.spawn(*cmd)
      end
      ::Process.detach(@pid) if detach?
    rescue => e
      raise LaunchError, e.message, e.backtrace
    end
  end
end
