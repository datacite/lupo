# frozen_string_literal: true

require "rails_helper"
def import_index(index_class)
  # Ensure index exists with proper mappings
  unless index_class.__elasticsearch__.client.indices.exists?(index: index_class.index_name)
    index_class.__elasticsearch__.create_index!
  end

  # Import with wait_for option to ensure completion
  index_class.import(refresh: true)
end

def clear_index(index_class)
  if index_class.__elasticsearch__.client.indices.exists?(index: index_class.index_name)
    # Delete and recreate index to ensure clean state
    index_class.__elasticsearch__.delete_index!
    index_class.__elasticsearch__.create_index!
  end
end

def reset_indices
  # Define order based on dependencies
  index_classes = [
    ProviderPrefix,
    ReferenceRepository,
    DataciteDoi,
    Client,
    Provider
  ]

  # Clear all indices first
  index_classes.each { |klass| clear_index(klass) }

  # Then import all with proper mappings
  index_classes.each { |klass| import_index(klass) }
end

describe MemberType do
  describe "fields", skip_prefix_pool: true do
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
    it do
      is_expected.to have_field(:repositories).of_type(
        "RepositoryConnectionWithTotal",
      )
    end
    it do
      is_expected.to have_field(:prefixes).of_type(
        "MemberPrefixConnectionWithTotal",
      )
    end
    it do
      is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal")
    end
    it do
      is_expected.to have_field(:publications).of_type(
        "PublicationConnectionWithTotal",
      )
    end
    it do
      is_expected.to have_field(:softwares).of_type(
        "SoftwareConnectionWithTotal",
      )
    end
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal") }
  end

  describe "query members", elasticsearch: false, prefix_pool_size: 6 do
    let!(:providers) { create_list(:provider, 6) }

    before do
      clear_index(Provider)
      import_index(Provider)
      @members = Provider.query(nil, page: { cursor: [], size: 6 }).results.to_a
    end

    let(:query) do
      "query {
        members(first: 5) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          years {
            id
            title
            count
          }
          regions {
            id
            title
            count
          }
          memberTypes {
            id
            title
            count
          }
          organizationTypes {
            id
            title
            count
          }
          focusAreas {
            id
            title
            count
          }
          nonProfitStatuses {
            id
            title
            count
          }
          nodes {
            id
            name
          }
        }
      }"
    end

    it "returns all members" do
      response = LupoSchema.execute(query).as_json
      current_year = Date.today.year.to_s

      expect(response.dig("data", "members", "totalCount")).to eq(6)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "members", "pageInfo", "endCursor"),
        ).
          split(",").
          last,
      ).to eq(@members[4].uid)
      expect(
        response.dig("data", "members", "pageInfo", "hasNextPage"),
      ).to be true

      expect(response.dig("data", "members", "years")).to eq(
        [{ "count" => 6, "id" => current_year, "title" => current_year }],
      )
      expect(response.dig("data", "members", "regions")).to eq(
        [
          {
            "count" => 6,
            "id" => "emea",
            "title" => "Europe, Middle East and Africa",
          },
        ],
      )
      expect(response.dig("data", "members", "memberTypes")).to eq(
        [{ "count" => 6, "id" => "direct_member", "title" => "Direct Member" }],
      )
      expect(response.dig("data", "members", "organizationTypes")).to eq([])
      expect(response.dig("data", "members", "focusAreas")).to eq([])
      expect(response.dig("data", "members", "nonProfitStatuses")).to eq(
        [{ "count" => 6, "id" => "non-profit", "title" => "Non Profit" }],
      )
      expect(response.dig("data", "members", "nodes").length).to eq(5)
      expect(response.dig("data", "members", "nodes", 0, "id")).to eq(
        @members.first.uid,
      )
      expect(response.dig("data", "members", "nodes", 0, "name")).to eq(
        @members.first.name,
      )
    end
  end

  describe "find member", elasticsearch: false, prefix_pool_size: 6 do
    let(:provider) { create(:provider, symbol: "TESTC") }
    let!(:client) { create(:client, provider: provider, software: "dataverse") }
    let!(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:provider_prefixes) do
      create_list(:provider_prefix, 3, provider: provider)
    end

    before do
      reset_indices
      @provider_prefixes =
        ProviderPrefix.query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        member(id: \"testc\") {
          id
          name
          country {
            name
          }
          memberRole {
            id
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
              clientId
              name
              software
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
      }"
    end

    it "returns member" do
      response = LupoSchema.execute(query).as_json
      current_year = Date.today.year.to_s

      expect(response.dig("data", "member", "id")).to eq(provider.uid)
      expect(response.dig("data", "member", "memberRole")).to eq(
        "id" => "direct_member", "name" => "Direct Member",
      )
      expect(response.dig("data", "member", "name")).to eq("My provider")
      expect(response.dig("data", "member", "country")).to eq(
        "name" => "Germany",
      )

      expect(
        response.dig("data", "member", "repositories", "totalCount"),
      ).to eq(1)
      expect(response.dig("data", "member", "repositories", "years")).to eq(
        [{ "count" => 1, "id" => current_year }],
      )
      expect(response.dig("data", "member", "repositories", "software")).to eq(
        [{ "count" => 1, "id" => "dataverse" }],
      )
      expect(
        response.dig("data", "member", "repositories", "nodes").length,
      ).to eq(1)
      repository1 = response.dig("data", "member", "repositories", "nodes", 0)
      expect(repository1.fetch("clientId")).to eq(client.uid)
      expect(repository1.fetch("name")).to eq(client.name)
      expect(repository1.fetch("software")).to eq(["dataverse"])

      expect(response.dig("data", "member", "prefixes", "totalCount")).to eq(4)
      # Remember when writing tests that the creation of a client will assign a prefix to that provider/client.
      # Then when we assign 3 more prefixes ot the provider, the count will be 4 total.
      expect(response.dig("data", "member", "prefixes", "years")).to eq(
        [{ "count" => 4, "id" => current_year }],
      )
      expect(response.dig("data", "member", "prefixes", "nodes").length).to eq(
        4,
      )
      prefix1 = response.dig("data", "member", "prefixes", "nodes", 0)
      expect(prefix1.fetch("name")).to eq(@provider_prefixes.first.prefix_id)
    end
  end
end
