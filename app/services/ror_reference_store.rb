# frozen_string_literal: true

require "aws-sdk-s3"

# Service for loading and caching ROR reference mapping files from S3.
#
# Each key-value pair from the mapping JSON is stored as its own cache entry,
# avoiding the need to assemble large Hashes in memory on every lookup.
#
# Cache key layout for mapping "funder_to_ror":
#   ror_ref/funder_to_ror/populated       => true   (written last, signals warm cache)
#   ror_ref/funder_to_ror/<funder_id>     => "<ror_id>"
#   ror_ref/funder_to_ror/<funder_id>     => "<ror_id>"
#   …
#
# For nested mappings like "ror_hierarchy":
#   ror_ref/ror_hierarchy/<ror_id>        => { "ancestors" => [...], ... }
#
class RorReferenceStore
  S3_PREFIX    = "ror_funder_mapping/"
  TTL          = 31.days
  POPULATED_KEY_SUFFIX = "populated"

  MAPPING_FILES = {
    funder_to_ror:    "funder_to_ror.json",
    ror_hierarchy:    "ror_hierarchy.json",
    ror_to_countries: "ror_to_countries.json",
  }.freeze

  class << self
    # Returns the ROR ID for a given funder ID suffix, or nil if not found.
    def funder_to_ror(funder_id)
      lookup(:funder_to_ror, funder_id)
    end

    # Returns the hierarchy Hash for a given ROR ID, or nil if not found.
    def ror_hierarchy(ror_id)
      lookup(:ror_hierarchy, ror_id)
    end

    # Returns the country data for a given ROR ID, or nil if not found.
    def ror_to_countries(ror_id)
      lookup(:ror_to_countries, ror_id)
    end

    # Downloads all three mappings from S3 and rewrites the cache.
    # Intended to be called from the monthly rake task.
    def refresh_all!
      MAPPING_FILES.each_key { |key| refresh!(key) }
    end

    private

    def lookup(mapping, key)
      value = Rails.cache.read(value_cache_key(mapping, key))
      unless value.nil?
        Rails.logger.info "[RorReferenceStore] hit: #{mapping}/#{key}"
        return value
      end

      # Value nil: might be cold cache or key not in mapping — check populated
      unless cache_populated?(mapping)
        Rails.logger.info "[RorReferenceStore] cache cold for #{mapping} – fetching from S3"
        refresh!(mapping)
        value = Rails.cache.read(value_cache_key(mapping, key))
      end
      Rails.logger.info "[RorReferenceStore] #{value ? 'hit' : 'miss'}: #{mapping}/#{key}"
      value
    end

    def cache_populated?(mapping)
      Rails.cache.read(populated_cache_key(mapping)) == true
    end

    def refresh!(mapping)
      body = download_from_s3(MAPPING_FILES[mapping])
      return nil if body.nil?

      hash = JSON.parse(body)

      # Write each key-value pair individually
      hash.each do |key, value|
        Rails.cache.write(value_cache_key(mapping, key), value, expires_in: TTL)
      end

      # Write the population signal last — only set after all keys are written
      Rails.cache.write(populated_cache_key(mapping), true, expires_in: TTL)

      Rails.logger.info "[RorReferenceStore] refreshed #{mapping} – #{hash.size} keys written"
      nil
    rescue JSON::ParserError => e
      Rails.logger.error "[RorReferenceStore] JSON parse error for #{mapping}: #{e.message}"
      nil
    end

    def download_from_s3(filename)
      bucket     = ENV["ROR_ANALYSIS_S3_BUCKET"]
      object_key = "#{S3_PREFIX}#{filename}"

      client   = Aws::S3::Client.new
      response = client.get_object(bucket: bucket, key: object_key)
      response.body.read
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "[RorReferenceStore] S3 download failed for #{filename}: #{e.message}"
      nil
    end

    def value_cache_key(mapping, key)
      "ror_ref/#{mapping}/#{key}"
    end

    def populated_cache_key(mapping)
      "ror_ref/#{mapping}/#{POPULATED_KEY_SUFFIX}"
    end
  end
end