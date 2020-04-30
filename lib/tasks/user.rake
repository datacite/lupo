# frozen_string_literal: true

namespace :user do
  desc "Generate jwt"
  task :generate_jwt => :environment do
    attributes = {
      uid: ENV['UID'] || "admin",
      name: ENV['NAME'] || "Admin",
      role_id: ENV['ROLE_ID'] || "staff_admin",
      provider_id: ENV['PROVIDER_ID'],
      client_id: ENV['CLIENT_ID'],
      beta_tester: ENV['BETA_TESTER'],
      email: ENV['EMAIL'],
      exp: (ENV['DAYS'] || "365").to_i.days,
      aud: ENV['AUD'] || Rails.env
    }

    token = User.generate_token(attributes)
    puts attributes.inspect + "\n\n"
    puts token
  end
end
