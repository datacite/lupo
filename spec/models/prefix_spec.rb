require 'rails_helper'

RSpec.describe Prefix, type: :model do
  let!(:prefixes)  { create_list(:prefix, 10) }
  let!(:prefix) { prefixes.first }
  describe "Validations" do
    it { should validate_presence_of(:prefix) }
  end

  describe "methods" do

    it "prefixes all" do
      collection = Prefix.all
      expect(collection.length).to eq(prefixes.length)
      single = collection.first
      expect(single.prefix).to eq(prefix.prefix)
      # meta = providers[:meta]
      # expect(meta["resource-types"]).not_to be_empty
      # expect(meta["years"]).not_to be_empty
      # expect(meta).not_to be_empty
    end

    it "prefixes with where year" do
      collection = Prefix.where("YEAR(prefix.created) = ?", prefix.created)
      single = collection.first
      expect(single.created.year).to eq(prefix.created.year)
      expect(single.prefix).to eq(prefix.prefix)
    end

    # it "providers with where sort by role_name" do
    #   collection = Prefix.where(name: "australia", sort: "role_name")
    #   expect(collection.length).to eq(1)
    #   provider = collection.first
    #   expect(prefix.name).to eq("Australian National Data Service")
    #   expect(prefix.symbol).to eq("ands")
    # end
    #
    # it "providers with where and resource-type-id" do
    #   collection = Prefix.where(where: "cancer", "resource-type-id" => "dataset")
    #   expect(collection[:data].length).to eq(3)
    #   provider = collection[:data].first
    #   expect(prefix.title).to eq("Landings of European lobster (Homarus gammarus) and edible crab (Cancer pagurus) in 2011, Helgoland, North Sea")
    #   expect(prefix.resource_type.title).to eq("Dataset")
    # end
    #
    # it "providers with where and resource-type-id and data-center-id" do
    #   collection = Prefix.where(where: "cancer", "resource-type-id" => "dataset", "data-center-id" => "FIGSHARE.ARS")
    #   expect(collection[:data].length).to eq(25)
    #   provider = collection[:data].first
    #   expect(prefix.title).to eq("Achilles_v3.3.7_README.txt")
    #   expect(prefix.resource_type.title).to eq("Dataset")
    # end

    it "prefixe" do
      single = Prefix.where(prefix: prefix.prefix).first
      expect(single.prefix).to eq(prefix.prefix)
      expect(single.created).to be_truthy
      expect(single.updated).to be_truthy
    end

  end
end
