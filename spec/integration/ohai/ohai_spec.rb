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
    it "the hostname plugin must return in under 4 seconds" do
      shell_out!("#{ohai} hostname", timeout: 4)
    end
  end
end
