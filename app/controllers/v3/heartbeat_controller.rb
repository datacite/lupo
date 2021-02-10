# frozen_string_literal: true

class V3::HeartbeatController < ApplicationController
  def index
    heartbeat = Heartbeat.new
    render plain: heartbeat.string,
           status: heartbeat.status,
           content_type: "text/plain"
  end
end
