# frozen_string_literal: true

namespace :provider_prefix do
  desc 'Generate uid'
  task :generate_uid => :environment do
    ProviderPrefix.where(uid: nil).each do |pp|
      pp.update_columns(uid: SecureRandom.uuid)
    end
  end
end
