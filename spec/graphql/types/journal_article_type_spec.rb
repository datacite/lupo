require "rails_helper"

describe Types::JournalArticleType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query journal articles", elasticsearch: true do
    let!(:journal_articles) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "JournalArticle" }, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        journalArticles {
          totalCount
          nodes {
            id
          }
        }
      })
    end

    it "returns all journal articles" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "journalArticles", "totalCount")).to eq(3)
      expect(response.dig("data", "journalArticles", "nodes").length).to eq(3)
      expect(response.dig("data", "journalArticles", "nodes", 0, "id")).to eq(journal_articles.first.identifier)
    end
  end

  describe "query journal articles by person", elasticsearch: true do
    let!(:journal_articles) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "JournalArticle" }, aasm_state: "findable") }
    let!(:journal_article) { create(:doi, types: { "resourceTypeGeneral" => "Text", "resourceType" => "JournalArticle" }, aasm_state: "findable", creators:
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
        journalArticles(userId: "https://orcid.org/0000-0003-1419-2405") {
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

    it "returns journal articles" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "journalArticles", "totalCount")).to eq(3)
      expect(response.dig("data", "journalArticles", "years")).to eq([{"count"=>3, "id"=>"2011"}])
      expect(response.dig("data", "journalArticles", "nodes").length).to eq(3)
      expect(response.dig("data", "journalArticles", "nodes", 0, "id")).to eq(journal_articles.first.identifier)
    end
  end
end
