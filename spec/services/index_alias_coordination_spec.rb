# frozen_string_literal: true

require "rails_helper"

describe IndexAliasCoordination do
  def reset_cluster_identity
    if described_class.instance_variable_defined?(:@cluster_identity)
      described_class.remove_instance_variable(:@cluster_identity)
    end
  end

  def lock_free?(lock)
    value = ActiveRecord::Base.connection.select_value(
      "SELECT IS_FREE_LOCK(#{ActiveRecord::Base.connection.quote(lock)})",
    )
    value.to_i == 1
  end

  describe "cache identity" do
    it "expires entries after 60 seconds" do
      expect(described_class::TTL).to eq(60.seconds)
      expect(Indexable::ClassMethods::ACTIVE_INDEX_CACHE_TTL).to eq(60.seconds)

      alias_name = "ttl-#{SecureRandom.hex(4)}"
      key = described_class.cache_key(alias_name)
      described_class.write_authoritative!(alias_name, "dois_v1")
      options = Rails.cache.send(:merged_options, nil)
      normalized = Rails.cache.send(:normalize_key, key, options)
      entry = Rails.cache.send(:read_entry, normalized, **options)

      expect(entry).not_to be_nil
      expect(entry.expires_at).to be_within(10).of(Time.now.to_f + 60)
    ensure
      Rails.cache.delete(described_class.cache_key(alias_name)) if alias_name
    end

    it "distinguishes environment and cluster in the key and the lock name" do
      original_host = ENV["ES_HOST"]
      reset_cluster_identity
      dev_key = described_class.cache_key("dois")
      dev_lock = described_class.lock_name("dois")

      ENV["ES_HOST"] = "other-cluster.example:9200"
      reset_cluster_identity
      other_cluster_key = described_class.cache_key("dois")
      other_cluster_lock = described_class.lock_name("dois")

      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      reset_cluster_identity
      other_env_key = described_class.cache_key("dois")
      other_env_lock = described_class.lock_name("dois")

      expect(dev_key).not_to eq(other_cluster_key)
      expect(dev_lock).not_to eq(other_cluster_lock)
      expect(other_cluster_key).not_to eq(other_env_key)
      expect(other_cluster_lock).not_to eq(other_env_lock)
      expect(dev_lock.length).to be <= 64
      expect(other_env_lock.length).to be <= 64
      expect(dev_lock).to start_with("lupo:alias:")
    ensure
      ENV["ES_HOST"] = original_host
      reset_cluster_identity
    end

    it "gives models that share an alias the same cache key and lock name" do
      expect(Doi.index_name).to eq(DataciteDoi.index_name)
      expect(Doi.active_index_cache_key).to eq(DataciteDoi.active_index_cache_key)
      expect(described_class.lock_name(Doi.index_name)).to eq(
        described_class.lock_name(DataciteDoi.index_name),
      )
    end
  end

  describe ".with_lock" do
    it "serializes two connections and contends between Doi and DataciteDoi" do
      alias_name = "dois-test-lock-#{SecureRandom.hex(4)}"
      holding = Queue.new
      release = Queue.new
      released = Queue.new
      observed = Queue.new

      holder = Thread.new do
        Rails.application.executor.wrap do
          described_class.with_lock(alias_name, timeout: 5) do
            holding << true
            release.pop(timeout: 10)
          end
          released << true
        end
      end

      expect(holding.pop(timeout: 10)).to be true

      waiter = Thread.new do
        Rails.application.executor.wrap do
          begin
            described_class.with_lock(alias_name, timeout: 0) { observed << :acquired_early }
          rescue described_class::LockTimeout
            observed << :timed_out
          end
          release << true
          released.pop(timeout: 10)
          described_class.with_lock(alias_name, timeout: 5) { observed << :acquired }
        end
      end

      waiter.join(15)
      holder.join(15)
      expect(holder).not_to be_alive
      expect(waiter).not_to be_alive
      expect(observed.pop(timeout: 1)).to eq(:timed_out)
      expect(observed.pop(timeout: 1)).to eq(:acquired)
      expect(lock_free?(described_class.lock_name(alias_name))).to be true

      shared = Doi.index_name
      expect(shared).to eq(DataciteDoi.index_name)
      shared_holding = Queue.new
      shared_release = Queue.new
      shared_holder = Thread.new do
        Rails.application.executor.wrap do
          described_class.with_lock(Doi.index_name, timeout: 5) do
            shared_holding << true
            shared_release.pop(timeout: 10)
          end
        end
      end
      expect(shared_holding.pop(timeout: 10)).to be true
      shared_error = nil
      shared_waiter = Thread.new do
        Rails.application.executor.wrap do
          described_class.with_lock(DataciteDoi.index_name, timeout: 0) { }
        end
      rescue StandardError => e
        shared_error = e
      end
      shared_waiter.join(10)
      shared_release << true
      shared_holder.join(10)
      expect(shared_error).to be_a(described_class::LockTimeout)
      expect(lock_free?(described_class.lock_name(shared))).to be true
    end

    it "does not serve GET_LOCK or RELEASE_LOCK from the query cache" do
      alias_name = "query-cache-#{SecureRandom.hex(4)}"
      lock = described_class.lock_name(alias_name)
      holder_id = ActiveRecord::Base.connection.select_value("SELECT CONNECTION_ID()").to_i
      cached_flags = []
      go_check = Queue.new
      checked_held = Queue.new
      go_free = Queue.new
      b_values = Queue.new

      checker = Thread.new do
        Rails.application.executor.wrap do
          ActiveRecord::Base.connection_pool.with_connection do |conn_b|
            go_check.pop(timeout: 10)
            b_values << conn_b.select_value("SELECT IS_USED_LOCK(#{conn_b.quote(lock)})")
            checked_held << true
            go_free.pop(timeout: 10)
            b_values << conn_b.select_value("SELECT IS_FREE_LOCK(#{conn_b.quote(lock)})")
          end
        end
      end

      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
        sql = payload[:sql].to_s
        next unless sql.include?("GET_LOCK") || sql.include?("RELEASE_LOCK")

        cached_flags << payload[:cached]
      end

      begin
        ActiveRecord::Base.cache do
          described_class.with_lock(alias_name) { }
          described_class.with_lock(alias_name) do
            go_check << true
            checked_held.pop(timeout: 10)
          end
        end
        go_free << true
        checker.join(15)
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(checker).not_to be_alive
      expect(b_values.pop(timeout: 1).to_i).to eq(holder_id)
      expect(b_values.pop(timeout: 1).to_i).to eq(1)
      expect(cached_flags).not_to be_empty
      expect(cached_flags).not_to include(true)
      expect(lock_free?(lock)).to be true
    end

    it "releases the lock when the block raises and propagates that exception" do
      alias_name = "raise-#{SecureRandom.hex(4)}"
      lock = described_class.lock_name(alias_name)

      expect do
        described_class.with_lock(alias_name) { raise "boom" }
      end.to raise_error(RuntimeError, "boom")

      expect(lock_free?(lock)).to be true
    end

    it "rejects a nested acquisition of the same lock" do
      alias_name = "nested-#{SecureRandom.hex(4)}"
      lock = described_class.lock_name(alias_name)

      expect do
        described_class.with_lock(alias_name) do
          described_class.with_lock(alias_name) { }
        end
      end.to raise_error(described_class::LockError, "nested acquisition")

      expect(lock_free?(lock)).to be true
    end
  end
end
