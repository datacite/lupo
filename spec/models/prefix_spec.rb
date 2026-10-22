# frozen_string_literal: true

require "rails_helper"

RSpec.describe Prefix, type: :model, prefix_pool_size: 1 do
  let!(:prefixes) { create_list(:prefix, 10) }
  let!(:prefix) { prefixes.first }

  after(:each) do
    Prefix.destroy_all
  end

  describe "Validations", skip_prefix_pool: true do
    it { should validate_presence_of(:uid) }
  end

  describe "methods" do
    it "prefixes all" do
      collection = Prefix.all
      expect(collection.length).to eq(prefixes.length + @prefix_pool.length)
      single = collection[@prefix_pool.length]
      expect(single.uid).to eq(prefix.uid)
      # meta = providers[:meta]
      # expect(meta["resource-types"]).not_to be_empty
      # expect(meta["years"]).not_to be_empty
      # expect(meta).not_to be_empty
    end

    it "prefixes with where year" do
      collection =
        Prefix.where("YEAR(prefixes.created_at) = ?", prefix.created_at)
      single = collection[@prefix_pool.length]
      expect(single.created_at.year).to eq(prefix.created_at.year)
      expect(single.uid).to eq(prefix.uid)
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
      single = Prefix.where(uid: prefix.uid).first
      expect(single.uid).to eq(prefix.uid)
      expect(single.created_at).to be_truthy
    end
  end
end

RSpec.describe Prefix, "lookups by uid", type: :model do
  let!(:provider) { create(:provider) }
  let(:uid) { build(:prefix).uid }

  def create_provider_prefix
    ProviderPrefix.create!(provider_id: provider.symbol, prefix_id: uid)
  end

  def expect_lookups_to_find_the_current_prefix
    current = Prefix.find_by!(uid: uid)

    # Client#assign_prefix passes the uid to ClientPrefix#prefix_id=
    create(:provider_prefix, provider: provider, prefix: current)
    client = create(:client, provider: provider)
    expect(client.reload.prefixes).to eq([current])

    # ProviderPrefix#prefix_id=
    other_provider = create(:provider)
    provider_prefix =
      ProviderPrefix.create!(provider_id: other_provider.symbol, prefix_id: uid)
    expect(provider_prefix.prefix).to eq(current)
  end

  it "resolves a uid that was destroyed and created again" do
    create(:prefix, uid: uid)
    create_provider_prefix
    Prefix.find_by!(uid: uid).destroy!

    create(:prefix, uid: uid)

    expect_lookups_to_find_the_current_prefix
  end

  it "resolves a uid whose earlier row was rolled back" do
    # Like DatabaseCleaner rolling back an earlier example: no commit
    # callback runs for the discarded row, so its id stays in the cache.
    ActiveRecord::Base.transaction(requires_new: true) do
      create(:prefix, uid: uid)
      create_provider_prefix
      raise ActiveRecord::Rollback
    end

    create(:prefix, uid: uid)

    expect_lookups_to_find_the_current_prefix
  end

  it "resolves a uid that was looked up before it existed" do
    expect { create_provider_prefix }.to raise_error(ActiveRecord::RecordNotFound)

    create(:prefix, uid: uid)

    expect_lookups_to_find_the_current_prefix
  end
end
