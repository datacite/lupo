# frozen_string_literal: true

require "digest"

# Identity, cache, and MySQL advisory lock for one OpenSearch index alias.
#
# GET_LOCK is connection-scoped and server-wide. Every web, worker, and rake
# process in an environment uses the same MySQL primary (there are no
# replicas). The lock name includes the Rails env and cluster identity, so
# environments that share a server do not contend. Acquisition and release
# run on one checked-out connection.
class IndexAliasCoordination
  class LockError < StandardError; end
  class LockTimeout < StandardError; end
  class CacheWriteFailed < StandardError
    attr_reader :expected, :actual

    def initialize(expected:, actual:)
      @expected = expected
      @actual = actual
      super("expected #{expected.inspect}, actual #{actual.inspect}")
    end
  end
  class AliasUpdateUnacknowledged < StandardError; end
  class UnsafeIndexOperation < StandardError; end

  TTL = 60.seconds

  # Same set as the test-suite searchable models, deduplicated by alias at use.
  INDEXED_MODELS = %w[
    Client
    Provider
    DataciteDoi
    OtherDoi
    Doi
    EnrichedDoi
    Event
    Activity
    Prefix
    ClientPrefix
    ProviderPrefix
    Contact
    ReferenceRepository
  ].freeze

  AliasState = Struct.new(:holders, :write_index, keyword_init: true) do
    def active
      return nil if holders.empty?
      return holders.first if holders.size == 1

      write_index || holders.first
    end

    def unambiguous_active
      holders.size == 1 ? holders.first : nil
    end
  end

  class << self
    def cluster_identity
      @cluster_identity ||= Digest::SHA256.hexdigest(ENV["ES_HOST"].to_s.strip.downcase)[0, 12]
    end

    def cache_key(alias_name)
      "elasticsearch/active_index/#{Rails.env}/#{cluster_identity}/#{alias_name}"
    end

    def lock_name(alias_name)
      "lupo:alias:" + Digest::SHA256.hexdigest("#{Rails.env}|#{cluster_identity}|#{alias_name}")[0, 40]
    end

    def lock_timeout
      ENV.fetch("INDEX_ALIAS_LOCK_TIMEOUT", "10").to_i
    end

    def with_lock(alias_name, timeout: nil)
      timeout = lock_timeout if timeout.nil?
      name = lock_name(alias_name)
      held = (Thread.current[:index_alias_locks] ||= {})
      raise LockError, "nested acquisition" if held[name]

      ActiveRecord::Base.connection_pool.with_connection do |connection|
        result = acquire_lock(connection, name, timeout)
        case normalize_lock_result(result)
        when 1
          held[name] = true
          begin
            yield
          ensure
            release_lock(connection, name)
            held.delete(name)
          end
        when 0
          raise LockTimeout, "timed out acquiring #{name}"
        else
          raise LockError, "GET_LOCK(#{name}) returned #{result.inspect}"
        end
      end
    end

    # Live alias holders. NotFound is an empty state. Every other transport
    # error propagates; only the read path rescues those to nil.
    def fetch_live(alias_name)
      response = Elasticsearch::Model.client.indices.get_alias(name: alias_name)
      holders = []
      write_index = nil

      response.each do |index_name, meta|
        holders << index_name.to_s
        next unless write_flag?(meta, alias_name)

        write_index ||= index_name.to_s
      end

      AliasState.new(holders: holders, write_index: write_index)
    rescue Elastic::Transport::Transport::Errors::NotFound
      AliasState.new(holders: [], write_index: nil)
    end

    # Assumes the alias lock is already held. Overwrites (or deletes) the key,
    # then reads it back. A mismatch gets one more delete; if the previous
    # value is still present, raises CacheWriteFailed.
    def write_authoritative!(alias_name, value)
      key = cache_key(alias_name)
      if value.nil?
        Rails.cache.delete(key)
      else
        Rails.cache.write(key, value, expires_in: TTL)
      end

      actual = Rails.cache.read(key)
      return if cache_value_matches?(actual, value)

      Rails.cache.delete(key)
      actual = Rails.cache.read(key)
      return if cache_value_matches?(actual, value)
      return if actual.nil?

      raise CacheWriteFailed.new(expected: value, actual: actual)
    end

    private
      def acquire_lock(connection, name, timeout)
        connection.uncached do
          connection.select_value("SELECT GET_LOCK(#{connection.quote(name)}, #{timeout.to_i})")
        end
      rescue LockError, LockTimeout
        raise
      rescue StandardError => e
        raise LockError, "GET_LOCK failed: #{e.class} #{e.message}"
      end

      def release_lock(connection, name)
        release = connection.uncached do
          connection.select_value("SELECT RELEASE_LOCK(#{connection.quote(name)})")
        end
        return if normalize_lock_result(release) == 1

        Rails.logger.error("[IndexAlias] RELEASE_LOCK(#{name}) returned #{release.inspect}")
      rescue StandardError => e
        Rails.logger.error("[IndexAlias] RELEASE_LOCK(#{name}) failed: #{e.class} #{e.message}")
      end

      def normalize_lock_result(result)
        return nil if result.nil?

        Integer(result)
      rescue ArgumentError, TypeError
        nil
      end

      def cache_value_matches?(actual, expected)
        expected.nil? ? actual.nil? : actual == expected
      end

      def write_flag?(meta, alias_name)
        aliases = meta["aliases"] || meta[:aliases] || {}
        entry = aliases[alias_name] || aliases[alias_name.to_sym]
        return false if entry.nil?

        flag = entry["is_write_index"]
        flag = entry[:is_write_index] if flag.nil?
        flag == true
      end
  end
end
