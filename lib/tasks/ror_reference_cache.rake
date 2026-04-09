# frozen_string_literal: true

namespace :ror do
  desc "Download ROR reference mapping files from S3 and refresh the Rails cache"
  task refresh_reference_cache: :environment do
    puts "Refreshing ROR reference cache from S3…"
    RorReferenceStore.refresh_all!
    puts "Done."
  end
end
