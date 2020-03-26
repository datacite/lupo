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
      expect(people.dig(:meta, "total")).to eq(96748)
      expect(people[:data].size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0003-0796-7209")
      expect(person.name).to eq("Peter  St George-Hyslop")
      expect(person.given_name).to eq("Peter")
      expect(person.family_name).to eq(" St George-Hyslop")
    end

    it "found" do
      query = "miller"
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(85)
      expect(people[:data].size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0003-0175-443X")
      expect(person.name).to eq("Hajira Dambha-Miller")
      expect(person.given_name).to eq("Hajira")
      expect(person.family_name).to eq("Dambha-Miller")
    end

    it "not found" do
      query = "xxx"
      people = Person.query(query)
      expect(people[:data]).to be_empty
    end
  end
end
