# frozen_string_literal: true

require "rails_helper"

describe Person, vcr: true, skip_prefix_pool: true do
  subject { Person }

  context "orcid_from_url" do
    it "orcid" do
      string = "https://orcid.org/0000-0003-2706-4082"
      expect(subject.orcid_from_url(string)).to eq("0000-0003-2706-4082")
    end

    it "orcid with lowercase X" do
      string = "https://orcid.org/0000-0001-7701-701x"
      expect(subject.orcid_from_url(string)).to eq("0000-0001-7701-701X")
    end

    it "orcid without protocol" do
      string = "orcid.org/0000-0003-2706-4082"
      expect(subject.orcid_from_url(string)).to be_nil
    end

    it "orcid not as url" do
      string = "0000-0003-2706-4082"
      expect(subject.orcid_from_url(string)).to be_nil
    end

    it "invalid orcid" do
      string = "XXXXX"
      expect(subject.orcid_from_url(string)).to be_nil
    end
  end

  context "orcid_url_from_identifier" do
    it "returns an ORCID URL unchanged" do
      expect(subject.orcid_url_from_identifier("https://orcid.org/0000-0003-2706-4082")).to eq(
        "https://orcid.org/0000-0003-2706-4082",
      )
    end

    it "builds a URL from an http ORCID URL" do
      expect(subject.orcid_url_from_identifier("http://orcid.org/0000-0003-2706-4082")).to eq(
        "https://orcid.org/0000-0003-2706-4082",
      )
    end

    it "builds a production URL from a sandbox ORCID URL" do
      expect(subject.orcid_url_from_identifier("https://sandbox.orcid.org/0000-0003-2706-4082")).to eq(
        "https://orcid.org/0000-0003-2706-4082",
      )
    end

    it "builds a URL from a bare ORCID id" do
      expect(subject.orcid_url_from_identifier("0000-0003-2706-4082")).to eq(
        "https://orcid.org/0000-0003-2706-4082",
      )
    end

    it "upcases a bare ORCID id ending in x" do
      expect(subject.orcid_url_from_identifier("0000-0001-7701-701x")).to eq(
        "https://orcid.org/0000-0001-7701-701X",
      )
    end

    it "returns nil for an OSF URL" do
      expect(subject.orcid_url_from_identifier("https://osf.io/8kzbu/")).to be_nil
    end

    it "returns nil for a blank value" do
      expect(subject.orcid_url_from_identifier(nil)).to be_nil
      expect(subject.orcid_url_from_identifier("  ")).to be_nil
    end

    it "returns nil for a string that is not an ORCID id" do
      expect(subject.orcid_url_from_identifier("0000-0003-2706-408")).to be_nil
      expect(subject.orcid_url_from_identifier("XXXXX")).to be_nil
    end
  end
end
