module Lupo
  class Application
    g = Git.open(Rails.root, :log => Logger.new(STDOUT))
    VERSION = g.tags.map { |t| Gem::Version.new(t.name) }.sort.last.to_s
    REVISION = g.object('HEAD').sha
  end
end