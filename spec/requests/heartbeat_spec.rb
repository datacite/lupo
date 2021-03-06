# frozen_string_literal: true

require "rails_helper"

describe "/heartbeat", type: :request do
  xit "get heartbeat" do
    get "/heartbeat"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("OK")
  end
end
