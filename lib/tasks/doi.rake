namespace :doi do
  desc 'Store handle URL'
  task :set_url => :environment do
    from_date = ENV['FROM_DATE'] || Time.zone.now - 1.day
    Doi.where(url: nil).where(aasm_state: ["registered", "findable"]).where("updated >= ?", from_date).find_each do |doi|
      UrlJob.perform_later(doi)
    end
  end

  desc 'Index all DOIs'
  task :index => :environment do
    from_date = ENV['FROM_DATE'] || Date.current.beginning_of_month.strftime("%F")
    until_date = ENV['UNTIL_DATE'] || Date.current.end_of_month.strftime("%F")

    response = Doi.index(from_date: from_date, until_date: until_date)
    puts response
  end

  desc 'Index DOIs per day'
  task :index_by_day => :environment do
    from_date = ENV['FROM_DATE'] || Date.current.strftime("%F")

    count = Doi.index_by_day(from_date: from_date)
    puts "DOIs updated on #{from_date} indexed with #{count} errors."
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

  desc 'Register all URLs'
  task :register_all_urls => :environment do
    limit = ENV['LIMIT'] || 100
    Doi.register_all_urls(limit: limit)
  end

  desc 'Delete DOIs with test prefix older than one month'
  task :delete_test_dois => :environment do
    from_date = ENV['FROM_DATE'] || Time.zone.now - 1.month
    Doi.delete_test_dois(from_date: from_date)
  end
end
