require 'rails_helper'

RSpec.describe Client, type: :model do
  let!(:clients)  { create_list(:client, 10) }
  let!(:client) { clients.first }
  let!(:dois) {  create_list(:doi, 5, client_id: client.symbol) }
  describe "Validations" do
    # it { should validate_presence_of(:symbol) }
    # it { should validate_presence_of(:name) }
    # it { should validate_presence_of(:contact_email) }
    # it { should validate_presence_of(:contact_name) }
  end

  describe "methods" do

    it "clients all" do
      collection = Client.all
      expect(collection.length).to eq(clients.length)
      single = collection.first
      expect(single.name).to eq(client.name)
      expect(single.role_name).to eq(client.role_name)
      # meta = clients[:meta]
      # expect(meta["resource-types"]).not_to be_empty
      # expect(meta["years"]).not_to be_empty
      # expect(meta).not_to be_empty
    end

    it "clients with where year" do
      collection = Client.where("YEAR(datacentre.created) = ?", client.created)
      single = collection.first
      expect(single.year).to eq(client.created.year)
      expect(single.name).to eq(client.name)
      expect(single.symbol).to eq(client.symbol)
    end

    it "should not update the symbol" do
      client.update_attributes :symbol => client.symbol+'foo.bar'
      expect(client.reload.symbol).to eq(client.symbol)
    end

    it "trasnfer all DOIS" do
      original_dois = Doi.where(client: client.symbol)
      target = clients.last
      expect(Doi.where(datacentre: client.id).count).to eq(5)
      expect(Doi.where(datacentre: target.id).count).to eq(0)
      client.target_id = target.symbol
      expect(Doi.where(datacentre: client.id).count).to eq(0)
      expect(Doi.where(datacentre: target.id).count).to eq(5)
    end

    # it "clients doi quota" do
    #   client.doi_quota_allowed = 5
    #
    #
    # end
    #
    # it "clients with where and resource-type-id" do
    #   collection = Client.where(where: "cancer", "resource-type-id" => "dataset")
    #   expect(collection[:data].length).to eq(3)
    #   client = collection[:data].first
    #   expect(client.title).to eq("Landings of European lobster (Homarus gammarus) and edible crab (Cancer pagurus) in 2011, Helgoland, North Sea")
    #   expect(client.resource_type.title).to eq("Dataset")
    # end
    #
    # it "clients with where and resource-type-id and data-center-id" do
    #   collection = Client.where(where: "cancer", "resource-type-id" => "dataset", "data-center-id" => "FIGSHARE.ARS")
    #   expect(collection[:data].length).to eq(25)
    #   client = collection[:data].first
    #   expect(client.title).to eq("Achilles_v3.3.7_README.txt")
    #   expect(client.resource_type.title).to eq("Dataset")
    # end

    it "client" do
      single = Client.where(symbol: client.symbol).first
      expect(single.name).to eq(client.name)
      expect(single.symbol).to eq(client.symbol)
      expect(single.role_name).to eq(client.role_name)
      expect(single.provider_id).to eq(client.provider_id)
      expect(single.created).to be_truthy
      expect(single.updated).to be_truthy
      expect(single.year).to be_truthy
      expect(single.domains).to be_truthy
      # expect(single.member).to be_truthy
      expect(single.repository).to be_nil
      expect(single.is_active).to be_truthy
      expect(single.doi_quota_allowed).to be_truthy
      expect(single.doi_quota_used).to be_truthy
    end
  end
end
