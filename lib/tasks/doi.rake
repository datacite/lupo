namespace :doi do
  desc 'Store handle URL'
  task :set_url => :environment do
    from_date = ENV['FROM_DATE'] || (Time.zone.now - 1.day).strftime("%F")
    response = Doi.set_url(from_date: from_date)
    puts response
  end

  desc 'Import all DOIs'
  task :import_all => :environment do
    if ENV['YEAR'].present?
      from_date = "#{ENV['YEAR']}-01-01"
      until_date = "#{ENV['YEAR']}-12-31"
    else
      from_date = ENV['FROM_DATE'] || Date.current.strftime("%F")
      until_date = ENV['UNTIL_DATE'] || Date.current.strftime("%F")
    end

    Doi.import_all(from_date: from_date, until_date: until_date)
  end

  desc 'Import DOIs per day'
  task :import_by_day => :environment do
    from_date = ENV['FROM_DATE'] || Date.current.strftime("%F")

    Doi.import_by_day(from_date: from_date)
    puts "DOIs created on #{from_date} imported."
  end

  desc 'Index all DOIs'
  task :index => :environment do
    if ENV['YEAR'].present?
      from_date = "#{ENV['YEAR']}-01-01"
      until_date = "#{ENV['YEAR']}-12-31"
    else
      from_date = ENV['FROM_DATE'] || Date.current.strftime("%F")
      until_date = ENV['UNTIL_DATE'] || Date.current.strftime("%F")
    end

    index_time = Time.zone.now.utc.iso8601

    Doi.index(from_date: from_date, until_date: until_date, index_time: index_time)
  end

  desc 'Index DOIs per day'
  task :index_by_day => :environment do
    from_date = ENV['FROM_DATE'] || Date.current.strftime("%F")

    Doi.index_by_day(from_date: from_date)
    puts "DOIs created on #{from_date} indexed."
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

  desc 'Update ALL DOIs link check landing page result to camelCase'
  task :update_landing_page_result_to_camel_Case => :environment do
    Doi.where.not('last_landing_page_status_result' => nil).find_each do |doi|
      begin
        result = doi.last_landing_page_status_result
        mappings = {
          "body-has-pid" => "bodyHasPid",
          "dc-identifier" => "dcIdentifier",
          "citation-doi" => "citationDoi",
          "redirect-urls" => "redirectUrls",
          "schema-org-id" => "schemaOrgId",
          "has-schema-org" => "hasSchemaOrg",
          "redirect-count" => "redirectCount",
          "download-latency" => "downloadLatency"
        }
        result = result.map {|k, v| [mappings[k] || k, v] }.to_h

        doi.update_columns("last_landing_page_status_result": result)
      rescue TypeError, NoMethodError => error
        logger.error "[MySQL] Error updating landing page result for " + doi.doi + ": " + error.message
      end
    end
  end
end
