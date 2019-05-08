require 'rails_helper'

describe Researcher, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://orcid.org/0000-0003-1419-2405"
      researchers = Researcher.find_by_id(id)
      expect(researchers.size).to eq(1)
      expect(researchers.first).to eq(id: "https://orcid.org/0000-0003-1419-2405", name: "Martin Fenner", "givenName" => "Martin", "familyName" => "Fenner")
    end

    it "not found" do
      id = "https://orcid.org/xxx"
      researchers = Researcher.find_by_id(id)
      expect(researchers).to be_empty
    end
  end
end