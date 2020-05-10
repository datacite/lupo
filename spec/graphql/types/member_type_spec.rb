require "rails_helper"

describe MemberType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:displayName).of_type("String!") }
    it { is_expected.to have_field(:rorId).of_type(types.ID) }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:website).of_type("Url") }
    it { is_expected.to have_field(:logoUrl).of_type("Url") }
    it { is_expected.to have_field(:region).of_type("String") }
    it { is_expected.to have_field(:country).of_type("Country") }
    it { is_expected.to have_field(:organizationType).of_type("String") }
    it { is_expected.to have_field(:focusArea).of_type("String") }
    it { is_expected.to have_field(:joined).of_type("ISO8601Date") }
    it { is_expected.to have_field(:repositories).of_type("RepositoryConnectionWithTotal") }
    it { is_expected.to have_field(:prefixes).of_type("MemberPrefixConnectionWithTotal") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnectionWithTotal") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnectionWithTotal") }
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal") }
  end

  describe "query members", elasticsearch: true do
    let!(:providers) { create_list(:provider, 3) }

    before do
      Provider.import
      sleep 2
    end

    let(:query) do
      %(query {
        members {
          totalCount
          years {
            title
            count
          }
          regions {
            title
            count
          }
          memberTypes {
            title
            count
          }
          organizationTypes {
            title
            count
          }
          focusAreas {
            title
            count
          }
          nonProfitStatuses {
            title
            count
          }
          nodes {
            id
            name
          }
        }
      })
    end

    it "returns all members" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "members", "totalCount")).to eq(3)
      expect(response.dig("data", "members", "years")).to eq([{"count"=>3, "title"=>"2020"}])
      expect(response.dig("data", "members", "regions")).to eq([{"count"=>3, "title"=>"Europe, Middle East and Africa"}])
      expect(response.dig("data", "members", "memberTypes")).to eq([{"count"=>3, "title"=>"Direct Member"}])
      expect(response.dig("data", "members", "organizationTypes")).to eq([])
      expect(response.dig("data", "members", "focusAreas")).to eq([])
      expect(response.dig("data", "members", "nonProfitStatuses")).to eq([{"count"=>3, "title"=>"Non Profit"}])
      expect(response.dig("data", "members", "nodes").length).to eq(3)
      expect(response.dig("data", "members", "nodes", 0, "id")).to eq(providers.first.uid)
      expect(response.dig("data", "members", "nodes", 0, "name")).to eq(providers.first.name)
    end
  end

  describe "find member", elasticsearch: true do
    let(:provider) { create(:provider, symbol: "TESTC") }
    let(:client) { create(:client, provider: provider, software: "dataverse") }
    let!(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:prefix) { create(:prefix) }
    let!(:provider_prefixes) { create_list(:provider_prefix, 3, provider: provider) }

    before do
      Provider.import
      Client.import
      Doi.import
      Prefix.import
      ProviderPrefix.import
      sleep 3
    end

    let(:query) do
      %(query {
        member(id: "testc") {
          id
          name
          country {
            name
          }
          repositories {
            totalCount
            years {
              id
              count
            }
            software {
              id
              count
            }
            nodes {
              id
              name
              software
              datasets {
                totalCount
              }
            }
          }
          prefixes {
            totalCount
            years {
              id
              count
            }
            nodes {
              name
            }
          }
        }
      })
    end

    it "returns member" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "member", "id")).to eq(provider.uid)
      expect(response.dig("data", "member", "name")).to eq("My provider")
      expect(response.dig("data", "member", "country")).to eq("name"=>"Germany")

      expect(response.dig("data", "member", "repositories", "totalCount")).to eq(1)
      expect(response.dig("data", "member", "repositories", "years")).to eq([{"count"=>1, "id"=>"2020"}])
      expect(response.dig("data", "member", "repositories", "software")).to eq([{"count"=>1, "id"=>"dataverse"}])
      expect(response.dig("data", "member", "repositories", "nodes").length).to eq(1)
      repository1 = response.dig("data", "member", "repositories", "nodes", 0)
      expect(repository1.fetch("id")).to eq(client.uid)
      expect(repository1.fetch("name")).to eq(client.name)
      expect(repository1.fetch("software")).to eq("dataverse")
      expect(repository1.dig("datasets", "totalCount")).to eq(1)

      expect(response.dig("data", "member", "prefixes", "totalCount")).to eq(3)
      expect(response.dig("data", "member", "prefixes", "years")).to eq([{"count"=>3, "id"=>"2020"}])
      expect(response.dig("data", "member", "prefixes", "nodes").length).to eq(3)
      prefix1 = response.dig("data", "member", "prefixes", "nodes", 0)
      expect(prefix1.fetch("name")).to eq(provider_prefixes.first.prefix_id)
    end
  end
end
