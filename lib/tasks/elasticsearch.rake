require 'elasticsearch/rails/tasks/import'

namespace :elasticsearch do
  namespace :re_index do
    desc "Re-index all models"
    task :all => :environment do
      Provider.__elasticsearch__.create_index! force: true
      Provider.__elasticsearch__.import do |response|
        puts "Got " + response['items'].select { |i| i['index']['error'] }.size.to_s + " errors"
      end

      Client.__elasticsearch__.create_index! force: true
      Client.__elasticsearch__.import do |response|
        puts "Got " + response['items'].select { |i| i['index']['error'] }.size.to_s + " errors"
      end
    end
  end

  namespace :create_index do
    desc "Create indexes"
    task :all => :environment do
      Provider.__elasticsearch__.create_index! force: true
      Client.__elasticsearch__.create_index! force: true
    end
  end
end
