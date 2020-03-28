require 'rails_helper'

describe Person, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://orcid.org/0000-0003-1519-3661"
      people = Person.find_by_id(id)
      expect(people[:data].size).to eq(1)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0003-1519-3661")
      expect(person.name).to eq("Peter Godfrey-Smith")
      expect(person.given_name).to eq("Peter")
      expect(person.family_name).to eq("Godfrey-Smith")
    end

    it "not found" do
      id = "https://orcid.org/xxxxx"
      people = Person.find_by_id(id)
      expect(people[:data]).to be_nil
      expect(people[:errors]).to be_nil
    end
  end

  describe "query" do
    it "all" do
      query = nil
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(648608)
      expect(people[:data].size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-8362-4294")
      expect(person.name).to eq("swoyam prakash    pandit ")
      expect(person.given_name).to eq("swoyam prakash ")
      expect(person.family_name).to eq("  pandit ")
    end

    it "found" do
      query = "miller"
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(428)
      expect(people[:data].size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-6219-6358")
      expect(person.name).to eq("Elizabeth A. (Miller) McGuier")
      expect(person.given_name).to eq("Elizabeth A.")
      expect(person.family_name).to eq("(Miller) McGuier")
    end

    it "not found" do
      query = "xxx"
      people = Person.query(query)
      expect(people[:data]).to be_empty
    end
  end
end
