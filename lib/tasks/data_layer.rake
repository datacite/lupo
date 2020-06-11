# frozen_string_literal: true

namespace :data_layer do
  desc "Sets all data services for the api"
  task create_all: :environment do
    fail "Seed tasks can only be used in the development enviroment" if Rails.env.production?

    STDOUT.puts "Your are trying to recreate all indexes and the database. Are you sure? (y/n)"
    input = STDIN.gets.strip
    if input == "y"
      Rake::Task["elasticsearch:create_all_indexes"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:schema:load"].invoke
      Rake::Task["db:seed:development:base"].invoke
    else
      puts "So sorry for the confusion"
    end
  end

  desc "removes all data services for the api"
  task delete_all: :environment do
    fail "Seed tasks can only be used in the development enviroment" if Rails.env.production?

    STDOUT.puts "Your are trying to delete all indexes and the database. Are you sure? (y/n)"
    input = STDIN.gets.strip
    if input == "y"
      Rake::Task["elasticsearch:delete_all_indexes"].invoke
      Rake::Task["db:drop"].invoke
    else
      puts "So sorry for the confusion"
    end
  end
end
