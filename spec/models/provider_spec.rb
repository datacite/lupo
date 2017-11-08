require 'rails_helper'

RSpec.describe Provider, type: :model do
  let!(:providers_factory)  { create_list(:provider, 25) }
  let!(:provider) { providers_factory.first }
  describe "Validations" do
    # it { should validate_presence_of(:symbol) }
    # it { should validate_presence_of(:name) }
    # it { should validate_presence_of(:contact_email) }
    # it { should validate_presence_of(:contact_name) }
  end

  describe "methods" do

    it "providers all" do
      collection = Provider.all
      expect(collection.length).to eq(providers_factory.length)
      single = collection.first
      expect(single.name).to eq(provider.name)
      expect(single.role_name).to eq(provider.role_name)
      # meta = providers[:meta]
      # expect(meta["resource-types"]).not_to be_empty
      # expect(meta["years"]).not_to be_empty
      # expect(meta).not_to be_empty
    end

    it "providers with where year" do
      collection = Provider.where("YEAR(allocator.created) = ?", provider.created)
      single = collection.first
      expect(single.year).to eq(provider.created.year)
      expect(single.name).to eq(provider.name)
      expect(single.symbol).to eq(provider.symbol)
    end

    it "should not update the symbol" do
      provider.update_attributes :symbol => provider.symbol+'foo.bar'
      provider.reload.symbol.should eql provider.symbol
    end

    # it "providers with where sort by role_name" do
    #   collection = Provider.where(name: "australia", sort: "role_name")
    #   expect(collection.length).to eq(1)
    #   provider = collection.first
    #   expect(provider.name).to eq("Australian National Data Service")
    #   expect(provider.symbol).to eq("ands")
    # end
    #
    # it "providers with where and resource-type-id" do
    #   collection = Provider.where(where: "cancer", "resource-type-id" => "dataset")
    #   expect(collection[:data].length).to eq(3)
    #   provider = collection[:data].first
    #   expect(provider.title).to eq("Landings of European lobster (Homarus gammarus) and edible crab (Cancer pagurus) in 2011, Helgoland, North Sea")
    #   expect(provider.resource_type.title).to eq("Dataset")
    # end
    #
    # it "providers with where and resource-type-id and data-center-id" do
    #   collection = Provider.where(where: "cancer", "resource-type-id" => "dataset", "data-center-id" => "FIGSHARE.ARS")
    #   expect(collection[:data].length).to eq(25)
    #   provider = collection[:data].first
    #   expect(provider.title).to eq("Achilles_v3.3.7_README.txt")
    #   expect(provider.resource_type.title).to eq("Dataset")
    # end

    it "provider" do
      single = Provider.where(symbol: provider.symbol).first
      expect(single.name).to eq(provider.name)
      expect(single.symbol).to eq(provider.symbol)
      expect(single.role_name).to eq(provider.role_name)
      expect(single.created).to be_truthy
      expect(single.updated).to be_truthy
      expect(single.region).to be_truthy
      expect(single.is_active).to be_truthy
      expect(single.doi_quota_allowed).to be_truthy
      expect(single.doi_quota_used).to be_truthy
    end
  end
end
