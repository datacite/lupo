# frozen_string_literal: true

require "rails_helper"

describe "Indexable alias mutations" do
  include ThrowawayAliasedIndex

  def stub_get_lock_result(value)
    connection = ActiveRecord::Base.connection
    allow(connection).to receive(:select_value).and_wrap_original do |method, *args, **kwargs|
      sql = args.first.to_s
      if sql.include?("GET_LOCK")
        value
      elsif kwargs.empty?
        method.call(*args)
      else
        method.call(*args, **kwargs)
      end
    end
  end

  describe "lock failure" do
    let(:indices) { Elasticsearch::Model.client.indices }

    before do
      stub_get_lock_result(0)
      allow(indices).to receive(:update_aliases)
      allow(Client.__elasticsearch__).to receive(:create_index!)
    end

    %i[switch_index create_alias delete_alias upgrade_index].each do |method_name|
      it "does not mutate or populate the cache when #{method_name} cannot acquire the lock" do
        key = Client.active_index_cache_key
        Rails.cache.write(key, "sentinel")

        expect { Client.public_send(method_name) }.to raise_error(IndexAliasCoordination::LockTimeout)
        expect(Rails.cache.read(key)).to eq("sentinel")
        expect(indices).not_to have_received(:update_aliases)
        expect(Client.__elasticsearch__).not_to have_received(:create_index!)
      end
    end
  end

  describe "real OpenSearch", :real_opensearch do
    let(:base) { throwaway_base }
    let(:custom_key) { Client.active_index_cache_key(base) }

    after do
      delete_throwaway("#{base}_v1", "#{base}_v2", "#{base}_other")
      Rails.cache.delete(custom_key)
      Rails.cache.delete(Client.active_index_cache_key)
    end

    it "refreshes only the custom alias key after switch_index" do
      v1, v2 = create_throwaway_pair(base, active: :v1)
      default_key = Client.active_index_cache_key
      Rails.cache.write(default_key, "sentinel")
      Rails.cache.write(custom_key, "stale")

      message = Client.switch_index(alias: base, index: base)

      expect(message).to eq("Switched active index to #{v2}.")
      expect(Rails.cache.read(custom_key)).to eq(v2)
      expect(Rails.cache.read(default_key)).to eq("sentinel")
      expect(opensearch_client.indices.exists_alias?(name: base, index: v2)).to be_truthy
      expect(v1).to be_present
    end

    it "resyncs each mutator to the live alias state" do
      allow(Client).to receive(:index_name).and_return(base)
      _v1, v2 = create_throwaway_pair(base, active: :v2)
      Rails.cache.write(custom_key, "stale")

      expect(Client.create_alias(alias: base, index: v2)).to include("already exists")
      expect(Rails.cache.read(custom_key)).to eq(v2)

      Rails.cache.write(custom_key, "stale")
      expect(Client.create_index(alias: base, index: base)).to include(v2)
      expect(Rails.cache.read(custom_key)).to eq(v2)

      Rails.cache.write(custom_key, "stale")
      expect(Client.switch_index(alias: base, index: base)).to include("#{base}_v1")
      expect(Rails.cache.read(custom_key)).to eq("#{base}_v1")

      Rails.cache.write(custom_key, "stale")
      Client.delete_index(index: "#{base}_v2")
      expect(Rails.cache.read(custom_key)).to eq("#{base}_v1")

      Rails.cache.write(custom_key, "stale")
      Client.delete_alias(alias: base, index: base)
      expect(Rails.cache.read(custom_key)).to be_nil
      expect(IndexAliasCoordination.fetch_live(base).active).to be_nil
    end

    it "keeps the original exception and resyncs after a failed alias update" do
      _v1, v2 = create_throwaway_pair(base, active: :v1)
      Rails.cache.write(custom_key, "stale")
      indices = opensearch_client.indices
      allow(indices).to receive(:update_aliases).and_wrap_original do |method, *args, **kwargs|
        kwargs.empty? ? method.call(*args) : method.call(*args, **kwargs)
        raise Faraday::TimeoutError, "timed out"
      end

      expect { Client.switch_index(alias: base, index: base) }.to raise_error(Faraday::TimeoutError)
      expect(Rails.cache.read(custom_key)).to eq(v2)
      expect(IndexAliasCoordination.fetch_live(base).holders).to eq([v2])
    end

    it "propagates the original exception and deletes the key when resync also fails" do
      create_throwaway_pair(base, active: :v1)
      Rails.cache.write(custom_key, "stale")
      calls = 0
      allow(IndexAliasCoordination).to receive(:fetch_live).and_wrap_original do |method, *args, **kwargs|
        calls += 1
        raise "resync failed" if calls > 1

        method.call(*args, **kwargs)
      end
      allow(opensearch_client.indices).to receive(:update_aliases).and_wrap_original do |method, *args, **kwargs|
        kwargs.empty? ? method.call(*args) : method.call(*args, **kwargs)
        raise Faraday::TimeoutError, "timed out"
      end

      expect { Client.switch_index(alias: base, index: base) }.to raise_error(Faraday::TimeoutError, "timed out")
      expect(Rails.cache.read(custom_key)).to be_nil
    end

    it "raises AliasUpdateUnacknowledged and stores the live holders" do
      _v1, v2 = create_throwaway_pair(base, active: :v1)
      Rails.cache.write(custom_key, "stale")
      allow(opensearch_client.indices).to receive(:update_aliases).and_wrap_original do |method, *args, **kwargs|
        kwargs.empty? ? method.call(*args) : method.call(*args, **kwargs)
        { "acknowledged" => false }
      end

      expect { Client.switch_index(alias: base, index: base) }.to raise_error(
        IndexAliasCoordination::AliasUpdateUnacknowledged,
      )
      expect(Rails.cache.read(custom_key)).to eq(v2)
    end
  end

  describe ".refresh_index_name_cache!" do
    let(:indices) { Elasticsearch::Model.client.indices }
    let(:alias_name) { Client.index_name }
    let(:key) { Client.active_index_cache_key }
    let(:live_index) { "#{alias_name}_v2" }

    before do
      allow(indices).to receive(:get_alias).with(name: alias_name).and_return(
        { live_index => { "aliases" => { alias_name => { "is_write_index" => true } } } },
      )
    end

    it "overwrites a stale value when delete is a no-op" do
      Rails.cache.write(key, "old")
      allow(Rails.cache).to receive(:delete).and_return(false)

      expect(Client.refresh_index_name_cache!).to eq(live_index)
      expect(Rails.cache.read(key)).to eq(live_index)
    end

    it "raises CacheWriteFailed when write and delete are both no-ops" do
      Rails.cache.write(key, "old")
      allow(Rails.cache).to receive(:write).and_return(false)
      allow(Rails.cache).to receive(:delete).and_return(false)

      expect { Client.refresh_index_name_cache! }.to raise_error(IndexAliasCoordination::CacheWriteFailed) { |error|
        expect(error.expected).to eq(live_index)
        expect(error.actual).to eq("old")
      }
      expect(Rails.cache.read(key)).to eq("old")
    end
  end
end
