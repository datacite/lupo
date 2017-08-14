require 'elasticsearch/rails/tasks/import'

namespace :elasticsearch do
  namespace :re_index do
    desc "Re-index all models"
    task :all => :environment do
      Member.__elasticsearch__.create_index! force: true
      Datacenter.__elasticsearch__.create_index! force: true
    end
  end
end
