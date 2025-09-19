namespace :index_sync do
  desc "Enables index syncing by setting the cache flag to true"
  task enable: :environment do
    Rails.cache.write("INDEX_SYNC_ENABLED", true)
    puts "✅ Index syncing has been ENABLED."
  end

  desc "Disables index syncing by setting the cache flag to false"
  task disable: :environment do
    Rails.cache.write("INDEX_SYNC_ENABLED", false)
    puts "❌ Index syncing has been DISABLED."
  end

  desc "Checks the current status of the index sync flag"
  task status: :environment do
    is_enabled = Rails.cache.read("INDEX_SYNC_ENABLED") == true
    if is_enabled
      puts "🟢 Index syncing is currently ENABLED."
    else
      puts "🔴 Index syncing is currently DISABLED."
    end
  end
end
