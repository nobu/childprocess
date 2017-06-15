require 'thread'
require 'childprocess/unix'

module ChildProcess
  class RubySpawnProcess < Unix::Process
    NULL = ::IO::NULL

    def stop(timeout = 3)
      assert_started
      begin
        send_term
      rescue Errno::EINVAL
        begin
          return poll_for_exit(timeout)
        rescue TimeoutError
          # try next
        end
      end

      send_kill
      wait
    rescue Errno::ECHILD, Errno::ESRCH
      # handle race condition where process dies between timeout
      # and send_kill
      true
    end

    private

    PGROUP_OPT = ChildProcess.windows? ? :new_pgroup : :pgroup
    def launch_process
      options = {}
      options[:out] = io.stdout || NULL
      options[:err] = io.stderr || NULL
      options[:chdir] = @cwd if @cwd
      options[PGROUP_OPT] = true if leader?
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
