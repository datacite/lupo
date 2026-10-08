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
      active = model.active_index
      inactive = model.inactive_index
      puts "  #{model_name}: active=#{active.inspect} inactive=#{inactive.inspect}"
    end
  end
end
