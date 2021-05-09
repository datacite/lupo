# frozen_string_literal: true
module V3
class HeartbeatController < ApplicationController
  def index
    heartbeat = Heartbeat.new
    render plain: heartbeat.string,
           status: heartbeat.status,
           content_type: "text/plain"
  end
end
end
