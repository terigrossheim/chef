require "spec_helper"
require "chef/mixin/shell_out"

describe "ohai" do
  include Chef::Mixin::ShellOut

  let(:ohai) { "bundle exec ohai" }

  describe "testing ohai performance" do
    # The purpose of this test is to generally find misconfigured DNS on
    # CI testers.  If this fails, it is probably because the forward+reverse
    # DNS lookup that node[:hostname] needs is timing out and failing.
    #
    # If it is failing spuriously, it may mean DNS is failing spuriously, the
    # best solution will be to make sure that `hostname -f`-like behavior hits
    # /etc/hosts and not DNS.
    #
    # If it still fails supriously, it is possible that the server has high
    # CPU load (e.g. due to background processes) which are contending with the
    # running tests (disable the screensaver on servers, stop playing Fortnite
    # while you're running tests, etc).
    #
    # If this just fails due to I/O being very slow and ruby being very slow to
    # startup then that still indicates that the tester configuration needs
    # fixing.  The fact that this will fail on a windows box on a virt that doesn't
    # use an SSD is because we have a higher bar for the tests to run successfully
    # and that configuration is broken, so this test is red for a reason.
    #
    # This will probably fail on raspberry pi's or something like that as well.  That
    # is not a bug.  We will never accept a raspberry pi as a CI tester for our
    # software.  Feel free to manually delete and thereby skip this file in your
    # own testing harness, but that is not our concern, we are testing behavior
    # that is critical to our infrastructure and must run in our tests.
    #
    it "the hostname plugin must return in under 4 seconds" do
      # we time the command and then compare to the timing result in order to display how long it actually took
      start = Time.now
      shell_out!("#{ohai} hostname")
      delta = Time.now - start
      expect(delta).to be < 0
    end

    # The purpose of this is to give some indication of if shell_out is slow or
    # if the hostname plugin itself is slow.  If this test is also failing that we
    # almost certainly have some kind of issue with DNS timeouts, etc.  If this
    # test succeeds and the other one fails, then it can be some kind of shelling-out
    # issue or poor performance due to I/O on starting up ruby to run ohai, etc.
    #
    it "the hostname plugin must also be fast when called from pure ruby" do
      start = Time.now
      Ohai::System.new.all_plugins(["hostname"])
      delta = Time.now - start
      expect(delta).to be < 0
    end
  end
end
