

require 'rails_helper'

describe Researcher, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://orcid.org/0000-0003-1419-2405"
      researchers = Researcher.find_by_id(id)
      expect(researchers[:data].size).to eq(1)
      expect(researchers[:data].first).to eq(id: "https://orcid.org/0000-0003-1419-2405", name: "Martin Fenner", "givenName" => "Martin", "familyName" => "Fenner")
    end

    it "not found" do
      id = "https://orcid.org/xxx"
      researchers = Researcher.find_by_id(id)
      expect(researchers[:data]).to be_nil
      expect(researchers[:errors]).to be_nil
    end
  end
end
