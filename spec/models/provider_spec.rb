require 'rails_helper'

RSpec.describe Provider, type: :model do
  describe "Validations" do
    # let!(:providerss)  { create_list(:provider, 45) }
    # it { should validate_presence_of(:symbol) }
    # it { should validate_presence_of(:name) }
    # it { should validate_presence_of(:contact_email) }
    # it { should validate_presence_of(:country_code) }


    it "providers" do
      providers = Provider.first(45)


      expect(providers.length).to eq(45)
      provider = providers.last
      expect(provider.name).to eq("European Inter-University Centre for Human Rights and Democratisation")
      expect(provider.role_name).to eq("ROLE_ALLOCATOR")
      # meta = providers[:meta]
      # expect(meta["resource-types"]).not_to be_empty
      # expect(meta["years"]).not_to be_empty
      # expect(meta).not_to be_empty
    end

    it "providers with query" do
      providers = Provider.query("*", {'loca' => 'ands'})
      expect(providers.length).to eq(1)
      provider = providers.first
      expect(provider.name).to eq("Australian National Data Service")
      expect(provider.symbol).to eq("ands")
    end

    it "providers with query sort by role_name" do
      providers = Provider.query(name: "australia", sort: "role_name")
      expect(providers.length).to eq(1)
      provider = providers.first
      expect(provider.name).to eq("Australian National Data Service")
      expect(provider.symbol).to eq("ands")
    end

    # it "providers with query and resource-type-id" do
    #   providers = Provider.where(query: "cancer", "resource-type-id" => "dataset")
    #   expect(providers[:data].length).to eq(3)
    #   provider = providers[:data].first
    #   expect(provider.title).to eq("Landings of European lobster (Homarus gammarus) and edible crab (Cancer pagurus) in 2011, Helgoland, North Sea")
    #   expect(provider.resource_type.title).to eq("Dataset")
    # end
    #
    # it "providers with query and resource-type-id and data-center-id" do
    #   providers = Provider.where(query: "cancer", "resource-type-id" => "dataset", "data-center-id" => "FIGSHARE.ARS")
    #   expect(providers[:data].length).to eq(25)
    #   provider = providers[:data].first
    #   expect(provider.title).to eq("Achilles_v3.3.7_README.txt")
    #   expect(provider.resource_type.title).to eq("Dataset")
    # end

    it "provider" do
      provider = Provider.query(id: "cdl")[:data]
      expect(provider.name).to eq("California Digital Library")
      expect(provider.symbol).to eq("cdl")
      expect(provider.role_name).to eq("ROLE_ALLOCATOR")
    end
  end
end
