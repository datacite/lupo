# frozen_string_literal: true

require "rails_helper"

describe "Indexable destructive index operations" do
  include ThrowawayAliasedIndex

  let(:base) { throwaway_base }
  let(:v1) { "#{base}_v1" }
  let(:v2) { "#{base}_v2" }

  before do
    allow(Client).to receive(:index_name).and_return(base)
  end

  after do
    delete_throwaway(v1, v2, "#{base}_other")
    Rails.cache.delete(Client.active_index_cache_key)
  end

  def seed_doc(index, id)
    opensearch_client.index(index: index, id: id, body: { marker: id }, refresh: true)
  end

  describe ".upgrade_index" do
    it "recreates the live inactive index when the cache is stale" do
      create_throwaway_pair(base, active: :v2)
      seed_doc(v1, "gone")
      seed_doc(v2, "stay")
      Rails.cache.write(Client.active_index_cache_key, v1)

      message = Client.upgrade_index

      expect(message).to eq("Upgraded inactive index #{v1}.")
      expect { opensearch_client.get(index: v1, id: "gone") }.to raise_error(
        Elastic::Transport::Transport::Errors::NotFound,
      )
      expect(opensearch_client.get(index: v2, id: "stay")["_id"]).to eq("stay")
      expect(IndexAliasCoordination.fetch_live(base).holders).to eq([v2])
      expect(Client.__elasticsearch__.index_exists?(index: v1)).to be_truthy
    end

    it "applies the refresh interval to the validated inactive index" do
      create_throwaway_pair(base, active: :v2)
      opensearch_client.indices.put_settings(
        index: v2,
        body: { index: { refresh_interval: "45s" } },
      )

      message = Client.upgrade_index(refresh_interval: "30s")

      expect(message).to include("Upgraded inactive index #{v1}.")
      expect(message).to include("to '30s'")
      expect(refresh_interval_of(v1)).to eq("30s")
      expect(refresh_interval_of(v2)).to eq("45s")
    end

    it "uses 120s when the refresh interval is nil or empty" do
      create_throwaway_pair(base, active: :v2)

      nil_message = Client.upgrade_index(refresh_interval: nil)
      expect(nil_message).to include("to '120s'")
      expect(refresh_interval_of(v1)).to eq("120s")

      empty_message = Client.upgrade_index(refresh_interval: "")
      expect(empty_message).to include("to '120s'")
      expect(refresh_interval_of(v1)).to eq("120s")
    end

    it "does not change settings when refresh_interval is omitted" do
      create_throwaway_pair(base, active: :v2)
      expect(opensearch_client.indices).not_to receive(:put_settings)

      expect(Client.upgrade_index).to eq("Upgraded inactive index #{v1}.")
    end

    it "rejects an explicit target that is the active index" do
      create_throwaway_pair(base, active: :v2)
      expect(Client.__elasticsearch__).not_to receive(:create_index!)

      expect { Client.upgrade_index(index: v2) }.to raise_error(IndexAliasCoordination::UnsafeIndexOperation)
      expect(opensearch_client.indices.exists(index: v2)).to be_truthy
    end

    it "rejects a missing alias" do
      [v1, v2].each do |index|
        opensearch_client.indices.create(
          index: index,
          body: { settings: { number_of_shards: 1, number_of_replicas: 0 } },
        )
      end
      expect(Client.__elasticsearch__).not_to receive(:create_index!)

      expect { Client.upgrade_index }.to raise_error(IndexAliasCoordination::UnsafeIndexOperation)
    end

    it "rejects an alias held by both versioned indexes" do
      create_throwaway_pair(base, active: :v1)
      opensearch_client.indices.update_aliases(
        body: { actions: [{ add: { index: v2, alias: base } }] },
      )
      seed_doc(v1, "keep-v1")
      seed_doc(v2, "keep-v2")
      expect(Client.__elasticsearch__).not_to receive(:create_index!)

      expect { Client.upgrade_index }.to raise_error(IndexAliasCoordination::UnsafeIndexOperation)
      expect(opensearch_client.get(index: v1, id: "keep-v1")["_id"]).to eq("keep-v1")
      expect(opensearch_client.get(index: v2, id: "keep-v2")["_id"]).to eq("keep-v2")
    end

    it "rejects an alias held by an unexpected index" do
      other = "#{base}_other"
      opensearch_client.indices.create(
        index: other,
        body: { settings: { number_of_shards: 1, number_of_replicas: 0 } },
      )
      opensearch_client.indices.update_aliases(
        body: { actions: [{ add: { index: other, alias: base } }] },
      )
      expect(Client.__elasticsearch__).not_to receive(:create_index!)

      expect { Client.upgrade_index }.to raise_error(IndexAliasCoordination::UnsafeIndexOperation)
      expect(opensearch_client.indices.exists(index: other)).to be_truthy
    end
  end

  describe ".set_refresh_interval" do
    it "sends 120s for a nil or empty interval and passes an explicit value through" do
      opensearch_client.indices.create(
        index: v1,
        body: { settings: { number_of_shards: 1, number_of_replicas: 0 } },
      )

      expect(opensearch_client.indices).to receive(:put_settings).with(
        index: v1,
        body: { index: { refresh_interval: "120s" } },
      ).and_call_original
      Client.set_refresh_interval(v1, nil)
      expect(refresh_interval_of(v1)).to eq("120s")

      expect(opensearch_client.indices).to receive(:put_settings).with(
        index: v1,
        body: { index: { refresh_interval: "120s" } },
      ).and_call_original
      Client.set_refresh_interval(v1, "")
      expect(refresh_interval_of(v1)).to eq("120s")

      expect(opensearch_client.indices).to receive(:put_settings).with(
        index: v1,
        body: { index: { refresh_interval: "5s" } },
      ).and_call_original
      Client.set_refresh_interval(v1, "5s")
      expect(refresh_interval_of(v1)).to eq("5s")
    end
  end

  describe ".delete_index" do
    it "refuses an aliased target unless force is true" do
      create_throwaway_pair(base, active: :v2)
      extra = "lupo-spec-extra-#{SecureRandom.hex(4)}"
      opensearch_client.indices.update_aliases(
        body: { actions: [{ add: { index: v2, alias: extra } }] },
      )
      Rails.cache.write(IndexAliasCoordination.cache_key(base), "stale")
      Rails.cache.write(IndexAliasCoordination.cache_key(extra), "stale")

      expect { Client.delete_index(index: v2) }.to raise_error(IndexAliasCoordination::UnsafeIndexOperation, /#{extra}/)
      expect(opensearch_client.indices.exists(index: v2)).to be_truthy
      expect(Rails.cache.read(IndexAliasCoordination.cache_key(base))).to eq("stale")

      allow(Rails.logger).to receive(:warn).and_call_original
      expect(Client.delete_index(index: v2, force: true)).to include("Deleted index #{v2}")
      expect(Rails.logger).to have_received(:warn).with(/aliases that will disappear: .*#{Regexp.escape(base)}/)
      expect(opensearch_client.indices.exists(index: v2)).to be_falsy
      expect(Rails.cache.read(IndexAliasCoordination.cache_key(base))).to be_nil
      expect(Rails.cache.read(IndexAliasCoordination.cache_key(extra))).to be_nil
      expect(IndexAliasCoordination.fetch_live(base).active).to be_nil
      expect(IndexAliasCoordination.fetch_live(extra).active).to be_nil
    ensure
      Rails.cache.delete(IndexAliasCoordination.cache_key(extra)) if extra
    end
  end
end

describe "datacite_doi:delete_index" do
  include_context "rake"
  include ThrowawayAliasedIndex

  let(:base) { throwaway_base }
  let(:target) { "#{base}_v1" }

  before do
    opensearch_client.indices.create(
      index: target,
      body: { settings: { number_of_shards: 1, number_of_replicas: 0 } },
    )
    opensearch_client.indices.update_aliases(
      body: { actions: [{ add: { index: target, alias: base } }] },
    )
  end

  after do
    delete_throwaway(target)
    ENV.delete("INDEX")
    ENV.delete("FORCE")
  end

  def invoke_delete(force)
    ENV["INDEX"] = target
    ENV["FORCE"] = force
    subject.reenable
    capture_stdout { subject.invoke }
  end

  it "does not override the guard for FORCE=yes or FORCE=1" do
    expect { invoke_delete("yes") }.to raise_error(IndexAliasCoordination::UnsafeIndexOperation)
    expect(opensearch_client.indices.exists(index: target)).to be_truthy

    expect { invoke_delete("1") }.to raise_error(IndexAliasCoordination::UnsafeIndexOperation)
    expect(opensearch_client.indices.exists(index: target)).to be_truthy
  end

  it "overrides the guard only for FORCE=true" do
    expect(invoke_delete("true")).to include("Deleted index #{target}")
    expect(opensearch_client.indices.exists(index: target)).to be_falsy
  end
end
