# frozen_string_literal: true

require "rails_helper"

describe Person, vcr: true do
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
end
