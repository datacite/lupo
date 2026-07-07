# frozen_string_literal: true

require "rails_helper"

describe "MDS misc endpoints", type: :request do
  let(:mds_host) { { "HTTP_HOST" => "mds.local" } }

  describe "GET /heartbeat" do
    it "returns OK without authentication" do
      get "/heartbeat", nil, mds_host

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("OK")
    end
  end

  describe "GET /login" do
    it "returns 501" do
      get "/login", nil, mds_host

      expect(last_response.status).to eq(501)
      expect(last_response.body).to include("session cookies not supported")
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
