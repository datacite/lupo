# frozen_string_literal: true

namespace :client_prefix do
  desc 'Generate uid'
  task :generate_uid => :environment do
    ClientPrefix.where(uid: nil).each do |cp|
      cp.update_columns(uid: SecureRandom.uuid)
    end
  end
end
