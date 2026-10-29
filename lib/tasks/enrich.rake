# frozen_string_literal: true

namespace :enrich do
  desc "Retired. The re3data endpoint is no longer active, so client subjects are not enriched from it"
  task client_subjects: :environment do
    puts "enrich:client_subjects is retired; the re3data endpoint is no longer active"
  end
end
