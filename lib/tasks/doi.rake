namespace :doi do
  desc 'Store handle URL'
  task :set_url => :environment do
    from_date = ENV['FROM_DATE'] || Time.zone.now - 1.day
    Doi.where(url: nil).where("updated >= ?", from_date).find_each do |doi|
      UrlJob.perform_later(doi)
    end
  end

  desc 'Set state'
  task :set_state => :environment do
    from_date = ENV['FROM_DATE'] || Time.zone.now - 1.day
    Doi.set_state(from_date: from_date)
  end

  desc 'Set minted'
  task :set_minted => :environment do
    from_date = ENV['FROM_DATE'] || Time.zone.now - 1.day
    Doi.set_minted(from_date: from_date)
  end

  desc 'Delete DOIs with test prefix older than one month'
  task :delete_test_dois => :environment do
    from_date = ENV['FROM_DATE'] || Time.zone.now - 1.month
    Doi.delete_test_dois(from_date: from_date)
  end
end
