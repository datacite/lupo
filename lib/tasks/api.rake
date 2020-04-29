# frozen_string_literal: true

namespace :api do
  desc "Sets all data services for the api"
  task up: :environment do
    Rake::Task["elasticsearch:create_all_indexes"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:schema:load"].invoke
    Rake::Task["db:seed:development:base"].invoke
  end

  desc "removes all data services for the api"
  task down: :environment do
    Rake::Task["elasticsearch:delete_all_indexes"].invoke
    Rake::Task["db:drop"].invoke
  end
end
