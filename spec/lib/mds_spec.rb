# frozen_string_literal: true

require "rails_helper"

describe Mds do
  def with_env(key, value)
    previous = ENV[key]
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
    yield
  ensure
    if previous.nil?
      ENV.delete(key)
    else
      ENV[key] = previous
    end
  end

  describe ".enabled?" do
    it "is true in the test environment by default" do
      # config/environments/test.rb enables MDS for contract specs on mds.local only
      expect(Mds.enabled?).to be(true)
    end

    it "is false when MDS_ENABLED is explicitly false" do
      with_env("MDS_ENABLED", "false") do
        expect(Mds.enabled?).to be(false)
      end
    end
  end

  describe ".host_match?" do
    it "matches configured MDS hosts" do
      request = double(host: "mds.local")
      expect(Mds.host_match?(request)).to be(true)
    end

    it "does not match Rack/Rails default hosts used by REST specs" do
      expect(Mds.host_match?(double(host: "www.example.com"))).to be(false)
      expect(Mds.host_match?(double(host: "example.org"))).to be(false)
    end

    it "does not match unrelated API hosts" do
      request = double(host: "api.datacite.org")
      expect(Mds.host_match?(request)).to be(false)
    end

    it "is case-insensitive for MDS hosts" do
      request = double(host: "MDS.LOCAL")
      expect(Mds.host_match?(request)).to be(true)
    end

    it "is false for all hosts when MDS is disabled" do
      with_env("MDS_ENABLED", "false") do
        expect(Mds.host_match?(double(host: "mds.local"))).to be(false)
      end
    end
  end

  describe ".hosts" do
    it "returns the dedicated test MDS host only" do
      expect(Mds.hosts).to eq(["mds.local"])
    end
  end
end
