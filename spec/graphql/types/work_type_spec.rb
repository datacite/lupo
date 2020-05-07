require "rails_helper"

describe WorkType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "find work", elasticsearch: true do
    let!(:work) { create(:doi, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        work(id: "https://doi.org/#{work.doi}") {
          id
          repository {
            id
            type
            name
          }
          member {
            id
            type
            name
          }
          bibtex
        }
      })
    end

    it "returns work" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "work", "id")).to eq("https://handle.test.datacite.org/#{work.doi.downcase}")
      expect(response.dig("data", "work", "repository", "id")).to eq(work.client_id)
      expect(response.dig("data", "work", "repository", "name")).to eq(work.client.name)
      expect(response.dig("data", "work", "member", "id")).to eq(work.provider_id)
      expect(response.dig("data", "work", "member", "name")).to eq(work.provider.name)
      expect(response.dig("data", "work", "id")).to eq("https://handle.test.datacite.org/#{work.doi.downcase}")
      bibtex = BibTeX.parse(response.dig("data", "work", "bibtex")).to_a(quotes: '').first
      expect(bibtex[:bibtex_type].to_s).to eq("misc")
      expect(bibtex[:bibtex_key]).to eq("https://doi.org/#{work.doi.downcase}")
      expect(bibtex[:author]).to eq("Ollomo, Benjamin and Durand, Patrick and Prugnolle, Franck and Douzery, Emmanuel J. P. and Arnathau, Céline and Nkoghe, Dieudonné and Leroy, Eric and Renaud, François")
      expect(bibtex[:title]).to eq("Data from: A new malaria agent in African hominids.")
      expect(bibtex[:year]).to eq("2011")
    end
  end
end
