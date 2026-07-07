# frozen_string_literal: true

require "rails_helper"

describe Mds do
  describe ".enabled?" do
    it "is true in the test environment by default" do
      expect(Mds.enabled?).to be(true)
    end
  end

  describe ".host_match?" do
    it "matches configured MDS hosts" do
      request = double(host: "mds.local")
      expect(Mds.host_match?(request)).to be(true)
    end

    it "does not match unrelated hosts" do
      request = double(host: "api.datacite.org")
      expect(Mds.host_match?(request)).to be(false)
    end

    it "is case-insensitive" do
      request = double(host: "MDS.LOCAL")
      expect(Mds.host_match?(request)).to be(true)
    end
  end

  describe ".hosts" do
    it "returns a list of downcased hosts" do
      expect(Mds.hosts).to include("mds.local")
    end
  end
end
