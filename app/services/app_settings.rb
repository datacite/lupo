# frozen_string_literal: true

class AppSettings
  # Use a constant to avoid magic strings scattered in your code
  INDEX_SYNC_KEY = "INDEX_SYNC_ENABLED".freeze

  # Define all methods on the class itself for easy access
  class << self
    def index_sync_enabled?
      Rails.cache.read(INDEX_SYNC_KEY) == true
    end

    def enable_index_sync!
      Rails.cache.write(INDEX_SYNC_KEY, true)
    end

    def disable_index_sync!
      Rails.cache.write(INDEX_SYNC_KEY, false)
    end
  end
end
