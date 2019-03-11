module Lupo
  class Application
    g = Git.open(Rails.root, :log => Logger.new(STDOUT))
    VERSION = "2.3.45"
    REVISION = g.object('HEAD').sha
  end
end