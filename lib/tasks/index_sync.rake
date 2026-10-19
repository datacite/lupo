# frozen_string_literal: true

namespace :index_sync do
  desc "Enables index syncing by setting the cache flag to true"
  task enable: :environment do
    SharedContainerSettings.enable_index_sync!
    puts "✅ Index syncing has been ENABLED."
  end

  desc "Disables index syncing by setting the cache flag to false"
  task disable: :environment do
    SharedContainerSettings.disable_index_sync!
    puts "❌ Index syncing has been DISABLED."
  end

  desc "Checks the current status of the index sync flag and cached index names"
  task status: :environment do
    if SharedContainerSettings.index_sync_enabled?
      puts "🟢 Index syncing is currently ENABLED."
    else
      puts "🔴 Index syncing is currently DISABLED."
    end

    SharedContainerSettings::INDEX_SYNC_MODELS.each do |model_name|
      model = model_name.constantize
      cached = Rails.cache.read(model.active_index_cache_key)
      begin
        state = IndexAliasCoordination.fetch_live(model.index_name)
        live = state.active
        holders = state.holders
        verdict =
          if holders.size > 1
            "AMBIGUOUS (#{holders.size} holders)"
          elsif cached.nil?
            "NOT CACHED"
          elsif cached == live
            "OK"
          else
            "DRIFT"
          end
        puts "  #{model_name}: cached=#{cached.inspect} live=#{live.inspect} holders=#{holders.inspect} #{verdict}"
      rescue StandardError => e
        puts "  #{model_name}: cached=#{cached.inspect} live=nil holders=nil UNRESOLVED (live lookup failed: #{e.class})"
      end
    end
  end
end
