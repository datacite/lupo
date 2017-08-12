require 'rails_helper'

describe '/heartbeat', type: :request do
  it "get heartbeat" do
    get '/heartbeat'

    expect(response.status).to eq(200)
    expect(response.body).to eq("OK")
  end
end
