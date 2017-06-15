require File.expand_path('../spec_helper', __FILE__)
require "pid_behavior"

if ChildProcess.unix? && !ChildProcess.jruby?

  describe ChildProcess::Unix::Process do
    it_behaves_like "a platform that provides the child's pid"

    it "handles ECHILD race condition where process dies between timeout and KILL" do
      process = sleeping_ruby

      allow(process).to receive(:fork).and_return('fakepid')
      allow(process).to receive(:send_term)
      allow(process).to receive(:poll_for_exit).and_raise(ChildProcess::TimeoutError)
      allow(process).to receive(:send_kill).and_raise(Errno::ECHILD.new)

      process.start
      expect { process.stop }.not_to raise_error

      allow(process).to receive(:alive?).and_return(false)

      process.send(:send_signal, 'TERM')
    end

    it "handles ESRCH race condition where process dies between timeout and KILL" do
      process = sleeping_ruby

      allow(process).to receive(:fork).and_return('fakepid')
      allow(process).to receive(:send_term)
      allow(process).to receive(:poll_for_exit).and_raise(ChildProcess::TimeoutError)
      allow(process).to receive(:send_kill).and_raise(Errno::ESRCH.new)

      process.start
      expect { process.stop }.not_to raise_error

      allow(process).to receive(:alive?).and_return(false)

      process.send(:send_signal, 'TERM')
    end
  end

end
