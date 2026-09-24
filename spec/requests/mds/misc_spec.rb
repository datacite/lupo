# frozen_string_literal: true

require "rails_helper"

describe "MDS misc endpoints", type: :request do
  let(:mds_host) { { "HTTP_HOST" => "mds.local" } }

  describe "GET /heartbeat" do
    it "uses Lupo Heartbeat (memcached probe) without authentication" do
      allow(Heartbeat).to receive(:new).and_return(
        instance_double(Heartbeat, string: "OK", status: 200),
      )

      get "/heartbeat", nil, mds_host

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("OK")
    end

    it "returns 500 when the shared heartbeat reports failure" do
      allow(Heartbeat).to receive(:new).and_return(
        instance_double(Heartbeat, string: "failed", status: 500),
      )

      get "/heartbeat", nil, mds_host

      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq("failed")
    end
  end

  describe "unknown path on MDS host" do
    it "returns MDS-style not found" do
      get "/not-a-real-mds-path", nil, mds_host

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("Resource not found")
    end
  end
end
