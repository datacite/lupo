# frozen_string_literal: true

require "rails_helper"

describe "Indexable active index cache" do
  let(:cache_key) { DataciteDoi.active_index_cache_key }
  let(:indices) { Elasticsearch::Model.client.indices }
  let(:alias_name) { DataciteDoi.index_name }
  let(:active_name) { "#{alias_name}_v1" }
  let(:inactive_name) { "#{alias_name}_v2" }

  before do
    Rails.cache.delete(cache_key)
  end

  after do
    Rails.cache.delete(cache_key)
  end

  describe ".active_index" do
    it "fetches from Elasticsearch once and caches the result" do
      allow(indices).to receive(:get_alias).with(name: alias_name).and_return(
        { active_name => { "aliases" => { alias_name => { "is_write_index" => true } } } },
      )

      expect(DataciteDoi.active_index).to eq(active_name)
      expect(DataciteDoi.active_index).to eq(active_name)
      expect(indices).to have_received(:get_alias).with(name: alias_name).once
      expect(Rails.cache.read(cache_key)).to eq(active_name)
    end

    it "does not raise or cache nil when Elasticsearch returns TooManyRequests" do
      allow(indices).to receive(:get_alias).with(name: alias_name).and_raise(
        Elastic::Transport::Transport::Errors::TooManyRequests.new("rate limited"),
      )

      expect(DataciteDoi.active_index).to be_nil
      expect(Rails.cache.read(cache_key)).to be_nil
    end

    it "does not raise or cache nil when the alias is NotFound" do
      allow(indices).to receive(:get_alias).with(name: alias_name).and_raise(
        Elastic::Transport::Transport::Errors::NotFound.new("alias missing"),
      )

      expect(DataciteDoi.active_index).to be_nil
      expect(Rails.cache.read(cache_key)).to be_nil
    end
  end

  describe ".inactive_index" do
    it "returns the complementary v1/v2 index without a second Elasticsearch call" do
      allow(indices).to receive(:get_alias).with(name: alias_name).and_return(
        { active_name => { "aliases" => { alias_name => { "is_write_index" => true } } } },
      )

      expect(DataciteDoi.inactive_index).to eq(inactive_name)
      expect(indices).to have_received(:get_alias).with(name: alias_name).once
    end

    it "returns nil when active_index cannot be resolved" do
      allow(indices).to receive(:get_alias).with(name: alias_name).and_raise(
        Elastic::Transport::Transport::Errors::TooManyRequests.new("rate limited"),
      )

      expect(DataciteDoi.inactive_index).to be_nil
    end
  end

  describe "cache identity" do
    it "includes the environment and expires in 60 seconds" do
      expect(cache_key).to eq(IndexAliasCoordination.cache_key(alias_name))
      expect(cache_key).to include("/#{Rails.env}/")
      expect(cache_key).not_to eq("elasticsearch/active_index/#{alias_name}")
      expect(Indexable::ClassMethods::ACTIVE_INDEX_CACHE_TTL).to eq(60.seconds)
    end

    it "accepts an optional alias argument on the test-env EnrichedDoi overrides" do
      expect(EnrichedDoi.active_index("other-alias")).to eq(EnrichedDoi.index_name)
      expect(EnrichedDoi.inactive_index("other-alias", base: "other-alias")).to eq(EnrichedDoi.index_name)
    end
  end

  describe ".refresh_index_name_cache!" do
    it "replaces the cached value with a live Elasticsearch fetch" do
      Rails.cache.write(cache_key, "#{alias_name}_v2")
      allow(indices).to receive(:get_alias).with(name: alias_name).and_return(
        { active_name => { "aliases" => { alias_name => { "is_write_index" => true } } } },
      )

      expect(DataciteDoi.refresh_index_name_cache!).to eq(active_name)
      expect(Rails.cache.read(cache_key)).to eq(active_name)
      expect(indices).to have_received(:get_alias).with(name: alias_name).once
    end
  end

  describe ".switch_index" do
    it "refreshes the active index cache from a live fetch after a successful switch" do
      allow(indices).to receive(:get_alias).with(name: alias_name).and_return(
        { active_name => { "aliases" => { alias_name => { "is_write_index" => true } } } },
        { inactive_name => { "aliases" => { alias_name => { "is_write_index" => true } } } },
      )
      allow(indices).to receive(:update_aliases).and_return({ "acknowledged" => true })
      Rails.cache.write(cache_key, active_name)

      message = DataciteDoi.switch_index

      expect(message).to include(inactive_name)
      expect(Rails.cache.read(cache_key)).to eq(inactive_name)
      expect(indices).to have_received(:get_alias).with(name: alias_name).twice
    end
  end
end
