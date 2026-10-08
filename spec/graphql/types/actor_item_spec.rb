# frozen_string_literal: true

require "rails_helper"

describe ActorItem do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
  end

  describe "find actor", vcr: true do
    let(:query) do
      "query {
        actor(id: \"https://ror.org/013meh722\") {
          id
          type
          name
          alternateName
        }
      }"
    end

    it "returns actor information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "actor", "id")).to eq(
        "https://ror.org/013meh722",
      )
      expect(response.dig("data", "actor", "type")).to eq("Organization")
      expect(response.dig("data", "actor", "name")).to eq(
        "University of Cambridge",
      )
    end
  end

  describe "find actor funder", vcr: true do
    let(:query) do
      "query {
        actor(id: \"https://doi.org/10.13039/501100003987\") {
          id
          type
          name
          alternateName
        }
      }"
    end

    it "returns actor information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "actor", "id")).to eq(
        "https://doi.org/10.13039/501100003987",
      )
      expect(response.dig("data", "actor", "type")).to eq("Funder")
      expect(response.dig("data", "actor", "name")).to eq(
        "James Baird Fund, University of Cambridge",
      )
    end
  end

  describe "find actor person", vcr: true do
    let(:query) do
      "query {
        actor(id: \"https://orcid.org/0000-0001-7701-701X\") {
          id
          type
          name
          alternateName
        }
      }"
    end

    xit "returns actor information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "actor", "id")).to eq(
        "https://orcid.org/0000-0001-7701-701X",
      )
      expect(response.dig("data", "actor", "type")).to eq("Person")
      expect(response.dig("data", "actor", "name")).to eq("Rory O'Bryen")
      expect(response.dig("data", "actor", "alternateName")).to eq([])
    end
  end

  describe "query actors", vcr: true do
    let(:query) do
      "query {
        actors(query: \"Cambridge University\") {
          totalCount
          nodes {
            id
            type
            name
            alternateName
          }
        }
      }"
    end

    xit "returns actor information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "actors", "totalCount")).to eq(1_956_171)
      expect(response.dig("data", "actors", "nodes").length).to eq(70)
      organization = response.dig("data", "actors", "nodes", 0)
      expect(organization.fetch("id")).to eq("https://ror.org/013meh722")
      expect(organization.fetch("name")).to eq("University of Cambridge")
      funder = response.dig("data", "actors", "nodes", 20)
      expect(funder.fetch("id")).to eq("https://doi.org/10.13039/501100009163")
      expect(funder.fetch("name")).to eq(
        "Centre of Latin American Studies, University of Cambridge",
      )
      person = response.dig("data", "actors", "nodes", 53)
      expect(person.fetch("id")).to eq("https://orcid.org/0000-0002-0929-8064")
      expect(person.fetch("name")).to eq("Dr Ahmed Izzidien")
    end
  end
end
