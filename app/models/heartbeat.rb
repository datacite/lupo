require "timeout"

class Heartbeat
  attr_reader :string, :status

  def initialize
    if memcached_up?
      @string = "OK"
      @status = 200
    else
      @string = "failed"
      @status = 500
    end
  end

  def memcached_up?
    memcached_client = Dalli::Client.new(ENV["MEMCACHE_SERVERS"])
    memcached_client.alive!
    true
  rescue StandardError
    false
  end
end
