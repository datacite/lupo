# frozen_string_literal: true

module Mds
  class HeartbeatController < Mds::ApplicationController
    def index
      render plain: "OK", status: :ok
    end
  end
end
