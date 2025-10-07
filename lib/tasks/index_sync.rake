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

  desc "Checks the current status of the index sync flag"
  task status: :environment do
    if SharedContainerSettings.index_sync_enabled?
      puts "🟢 Index syncing is currently ENABLED."
    else
      puts "🔴 Index syncing is currently DISABLED."
    end
  end
end
