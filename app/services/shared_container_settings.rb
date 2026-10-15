# frozen_string_literal: true

class SharedContainerSettings
  # Use a constant to avoid magic strings scattered in your code
  INDEX_SYNC_KEY = "INDEX_SYNC_ENABLED"
  INDEX_SYNC_MODELS = %w[DataciteDoi OtherDoi EnrichedDoi].freeze

  # Define all methods on the class itself for easy access
  class << self
    def index_sync_enabled?
      Rails.cache.read(INDEX_SYNC_KEY) == true
    end

    def enable_index_sync!
      Rails.cache.write(INDEX_SYNC_KEY, true)
      warm_index_name_caches!
    end

    def disable_index_sync!
      Rails.cache.write(INDEX_SYNC_KEY, false)
    end

    # Refresh cached active/inactive index names for DOI models used during sync.
    def warm_index_name_caches!
      INDEX_SYNC_MODELS.each do |model_name|
        model = model_name.constantize
        model.refresh_index_name_cache!
      rescue StandardError => e
        Rails.logger.warn(
          "[IndexSync] Failed to warm index name cache for #{model_name}: #{e.class} #{e.message}",
        )
      end
    end
  end
end
