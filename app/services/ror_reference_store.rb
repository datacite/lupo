# frozen_string_literal: true

require "aws-sdk-s3"

# Service for loading and caching ROR reference mapping files from S3.
#
# Memcached has a ~1 MB item limit, so large JSON files are split into
# fixed-size chunks and stored under individual cache keys.  A lightweight
# "meta" key records how many chunks exist so the reader can reassemble the
# original JSON without hitting S3 again.
#
# Cache key layout for mapping "funder_to_ror":
#   ror_ref/funder_to_ror/meta  => { "chunks" => N }   (Hash)
#   ror_ref/funder_to_ror/0     => "<first 512 KB of JSON>"
#   ror_ref/funder_to_ror/1     => "<next  512 KB …>"
#   …
class RorReferenceStore
  S3_PREFIX = "ror_funder_mapping/"
  CHUNK_SIZE = 512 * 1024 # 512 KB – well below Memcached's 1 MB limit

  MAPPING_FILES = {
    funder_to_ror:   "funder_to_ror.json",
    ror_hierarchy:   "ror_hierarchy.json",
    ror_to_countries: "ror_to_countries.json",
  }.freeze

  class << self
    def funder_to_ror
      load_mapping(:funder_to_ror)
    end

    def ror_hierarchy
      load_mapping(:ror_hierarchy)
    end

    def ror_to_countries
      load_mapping(:ror_to_countries)
    end

    # Downloads all three mappings from S3 and rewrites the cache.
    def refresh_all!
      MAPPING_FILES.each_key { |key| refresh!(key) }
    end

    private

    def load_mapping(key)
      json = read_from_cache(key)
      if json
        Rails.logger.info "[RorReferenceStore] cache hit: #{key}"
        return json
      end

      Rails.logger.info "[RorReferenceStore] cache miss: #{key} – fetching from S3"
      refresh!(key)
    end

    # Downloads the mapping from S3, writes chunked cache keys, and returns
    # the parsed Hash.  Returns nil on failure so callers can degrade
    # gracefully.
    def refresh!(key)
      body = download_from_s3(MAPPING_FILES[key])
      return nil if body.nil?

      write_to_cache(key, body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      Rails.logger.error "[RorReferenceStore] JSON parse error for #{key}: #{e.message}"
      nil
    end

    # Reassembles chunks from cache.  Returns nil if any chunk is missing.
    def read_from_cache(key)
      meta = Rails.cache.read(meta_cache_key(key))
      return nil if meta.nil?

      chunk_count = meta["chunks"]
      chunks = (0...chunk_count).map { |i| Rails.cache.read(chunk_cache_key(key, i)) }
      return nil if chunks.any?(&:nil?)

      JSON.parse(chunks.join)
    rescue JSON::ParserError => e
      Rails.logger.error "[RorReferenceStore] JSON parse error reading cache for #{key}: #{e.message}"
      nil
    end

    def write_to_cache(key, body)
      chunks = body.scan(/.{1,#{CHUNK_SIZE}}/m)
      chunks.each_with_index do |chunk, i|
        Rails.cache.write(chunk_cache_key(key, i), chunk, expires_in: 25.hours)
      end
      Rails.cache.write(meta_cache_key(key), { "chunks" => chunks.size }, expires_in: 25.hours)
    end

    def download_from_s3(filename)
      bucket = ENV["ROR_ANALYSIS_S3_BUCKET"]
      object_key = "#{S3_PREFIX}#{filename}"

      client = Aws::S3::Client.new
      response = client.get_object(bucket: bucket, key: object_key)
      response.body.read
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "[RorReferenceStore] S3 download failed for #{filename}: #{e.message}"
      nil
    end

    def meta_cache_key(key)
      "ror_ref/#{key}/meta"
    end

    def chunk_cache_key(key, index)
      "ror_ref/#{key}/#{index}"
    end
  end
end
