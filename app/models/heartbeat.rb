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
    memcached_client = Dalli::Client.new
    memcached_client.alive!
    true
  rescue
    false
  end
end
