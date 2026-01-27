# frozen_string_literal: true

require "rails_helper"

describe ConferencePaperType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query conference papers", elasticsearch: true do
    let!(:conference_papers) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Conference paper" }, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        conferencePapers {
          totalCount
          nodes {
            id
          }
        }
      })
    end

    it "returns all conference papers" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "conferencePapers", "totalCount")).to eq(3)
      expect(response.dig("data", "conferencePapers", "nodes").length).to eq(3)
      expect(response.dig("data", "conferencePapers", "nodes", 0, "id")).to eq(conference_papers.first.identifier)
    end
  end

  describe "query conference papers by person", elasticsearch: true do
    let!(:conference_papers) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Conference paper" }, aasm_state: "findable") }
    let!(:conference_paper) do
      create(:doi, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Conference paper" }, aasm_state: "findable", creators:
      [{
        "familyName" => "Garza",
        "givenName" => "Kristian",
        "name" => "Garza, Kristian",
        "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }],
        "nameType" => "Personal",
      }])
    end
    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        conferencePapers(userId: "https://orcid.org/0000-0003-1419-2405") {
          totalCount
          years {
            id
            count
          }
          nodes {
            id
          }
        }
      })
    end

    it "returns conference papers" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "conferencePapers", "totalCount")).to eq(3)
      expect(response.dig("data", "conferencePapers", "years")).to eq([{ "count" => 3, "id" => "2011" }])
      expect(response.dig("data", "conferencePapers", "nodes").length).to eq(3)
      expect(response.dig("data", "conferencePapers", "nodes", 0, "id")).to eq(conference_papers.first.identifier)
    end
  end
end
