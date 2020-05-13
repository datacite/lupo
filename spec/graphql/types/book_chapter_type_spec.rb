require "rails_helper"

describe BookChapterType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query book chapters", elasticsearch: true do
    let!(:book_chapters) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "BookChapter" }, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        bookChapters {
          totalCount
          nodes {
            id
          }
        }
      })
    end

    it "returns all book chapters" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "bookChapters", "totalCount")).to eq(3)
      expect(response.dig("data", "bookChapters", "nodes").length).to eq(3)
      expect(response.dig("data", "bookChapters", "nodes", 0, "id")).to eq(book_chapters.first.identifier)
    end
  end

  describe "query book chapters by person", elasticsearch: true do
    let!(:book_chapters) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "BookChapter" }, aasm_state: "findable") }
    let!(:book_chapter) { create(:doi, types: { "resourceTypeGeneral" => "Text", "resourceType" => "BookChapter" }, aasm_state: "findable", creators:
      [{
        "familyName" => "Garza",
        "givenName" => "Kristian",
        "name" => "Garza, Kristian",
        "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
        "nameType" => "Personal",
      }])
    }
    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        bookChapters(userId: "https://orcid.org/0000-0003-1419-2405") {
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

    it "returns book chapters" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "bookChapters", "totalCount")).to eq(3)
      expect(response.dig("data", "bookChapters", "years")).to eq([{"count"=>3, "id"=>"2011"}])
      expect(response.dig("data", "bookChapters", "nodes").length).to eq(3)
      expect(response.dig("data", "bookChapters", "nodes", 0, "id")).to eq(book_chapters.first.identifier)
    end
  end
end
