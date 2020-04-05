require "rails_helper"

describe ProviderType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:displayName).of_type("String") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:clients).of_type("ClientConnection") }
    it { is_expected.to have_field(:prefixes).of_type("ProviderPrefixConnection") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnection") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnection") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnection") }
    it { is_expected.to have_field(:works).of_type("WorkConnection") }
  end

  describe "query providers", elasticsearch: true do
    let!(:providers) { create_list(:provider, 3) }

    before do
      Provider.import
      sleep 2
    end

    let(:query) do
      %(query {
        providers {
          totalCount
          nodes {
            id
            name
          }
        }
      })
    end

    it "returns all providers" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "providers", "totalCount")).to eq(3)
      expect(response.dig("data", "providers", "nodes").length).to eq(3)
      expect(response.dig("data", "providers", "nodes", 0, "id")).to eq(providers.first.uid)
    end
  end

  describe "find provider", elasticsearch: true do
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
        provider(id: "testc") {
          id
          name
          country {
            name
          }
          clients {
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

    it "returns provider" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "provider", "id")).to eq(provider.uid)
      expect(response.dig("data", "provider", "name")).to eq("My provider")
      expect(response.dig("data", "provider", "country")).to eq("name"=>"Germany")

      expect(response.dig("data", "provider", "clients", "totalCount")).to eq(1)
      expect(response.dig("data", "provider", "clients", "years")).to eq([{"count"=>1, "id"=>"2020"}])
      expect(response.dig("data", "provider", "clients", "software")).to eq([{"count"=>1, "id"=>"dataverse"}])
      expect(response.dig("data", "provider", "clients", "nodes").length).to eq(1)
      client1 = response.dig("data", "provider", "clients", "nodes", 0)
      expect(client1.fetch("id")).to eq(client.uid)
      expect(client1.fetch("name")).to eq(client.name)
      expect(client1.fetch("software")).to eq("dataverse")
      expect(client1.dig("datasets", "totalCount")).to eq(1)

      expect(response.dig("data", "provider", "prefixes", "totalCount")).to eq(3)
      expect(response.dig("data", "provider", "prefixes", "years")).to eq([{"count"=>3, "id"=>"2020"}])
      expect(response.dig("data", "provider", "prefixes", "nodes").length).to eq(3)
      prefix1 = response.dig("data", "provider", "prefixes", "nodes", 0)
      expect(prefix1.fetch("name")).to eq(provider_prefixes.first.prefix_id)
    end
  end
end
