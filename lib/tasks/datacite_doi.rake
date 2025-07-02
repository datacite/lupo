# frozen_string_literal: true

namespace :datacite_doi do
  desc "Create index for datacite dois"
  task create_index: :environment do
    puts DataciteDoi.create_index(alias: ENV["ALIAS"], index: ENV["INDEX"])
  end

  desc "Delete index for datacite dois"
  task delete_index: :environment do
    puts DataciteDoi.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for datacite dois"
  task upgrade_index: :environment do
    puts DataciteDoi.upgrade_index(index: ENV["INDEX"])
  end

  desc "Create alias for datacite dois"
  task create_alias: :environment do
    puts DataciteDoi.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Delete alias for datacite dois"
  task delete_alias: :environment do
    puts DataciteDoi.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Show index stats for datacite dois"
  task index_stats: :environment do
    puts DataciteDoi.index_stats(active_index: ENV["ACTIVE"], inactive_index: ENV["INACTIVE"])
  end

  desc "Switch index for datacite dois"
  task switch_index: :environment do
    puts DataciteDoi.switch_index(alias: ENV["ALIAS"], index: ENV["INDEX"])
  end

  desc "Return active index for datacite dois"
  task active_index: :environment do
    puts DataciteDoi.active_index + " is the active index."
  end

  desc "Monitor reindexing for datacite dois"
  task monitor_reindex: :environment do
    puts DataciteDoi.monitor_reindex
  end

  desc "Create template for datacite dois"
  task create_template: :environment do
    puts DataciteDoi.create_template
  end

  desc "Delete template for datacite dois"
  task delete_template: :environment do
    puts DataciteDoi.delete_template
  end

  desc "Delete aliases for dois"
  task delete_alias: :environment do
    puts DataciteDoi.delete_alias
  end

  desc "Index all datacite DOIs grouped by Client"
  task index_all_by_client: :environment do
    import_index = ENV["INDEX"] || DataciteDoi.inactive_index
    batch_size = ENV["BATCH_SIZE"].nil? ? 2000 : ENV["BATCH_SIZE"].to_i
    DataciteDoi.index_all_by_client(
      index: import_index,
      batch_size: batch_size,
    )
  end

  desc "Import all datacite DOIs for a given Client(id)"
  task import_by_client: :environment do
    if ENV["CLIENT_ID"].nil?
      puts "ENV variable CLIENT_ID is required"
      exit
    end
    import_index = ENV["INDEX"] || DataciteDoi.inactive_index
    batch_size = ENV["BATCH_SIZE"].nil? ? 2000 : ENV["BATCH_SIZE"].to_i
    DataciteDoi.import_by_client(
      client_id: ENV["CLIENT_ID"],
      import_index: import_index,
      batch_size: batch_size,
    )
  end

  desc "Import all datacite DOIs"
  task import: :environment do
    from_id = (ENV["FROM_ID"] || DataciteDoi.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || DataciteDoi.maximum(:id)).to_i
    batch_size = ENV["BATCH_SIZE"].nil? ? 50 : ENV["BATCH_SIZE"].to_i

    DataciteDoi.import_by_ids(
      from_id: from_id,
      until_id: until_id,
      batch_size: batch_size,
      index: ENV["INDEX"] || DataciteDoi.inactive_index
    )
  end

  desc "Import one datacite DOI"
  task import_one: :environment do
    if ENV["DOI"].nil? && ENV["ID"].nil?
      puts "Either ENV variable DOI or ID are required"
      exit
    end

    puts DataciteDoi.import_one(doi_id: ENV["DOI"], id: ENV["ID"])
  end

  desc "Index one datacite DOI"
  task index_one: :environment do
    if ENV["DOI"].nil?
      puts "ENV['DOI'] is required"
      exit
    end
    puts DataciteDoi.index_one(doi_id: ENV["DOI"])
  end
end

namespace :nifs_dois do
  desc "Process nifs events"
  task process_events: :environment do
    puts("Start importing NIFS events")
    puts("Reading environment variables")

    if ENV["START_DATE"].blank?
      puts("ERROR: START_DATE environment variable not set")
      exit
    end

    start_date = Time.parse(ENV["START_DATE"]).to_date
    puts("Start date: #{start_date}")

    if ENV["END_DATE"].blank?
      puts("ERROR: END_DATE environment variable not set")
      exit
    end

    end_date = Time.parse(ENV["END_DATE"]).to_date
    puts("End date: #{end_date}")

    response = Doi.query(
      "client.id:rpht.nifs AND created:[#{start_date} TO #{end_date}}",
      { page: { size: 1, cursor: [] } })

    if response.results.total.zero?
      puts("No NIFS DOIs found for the specified date range.")
      exit
    end

    cursor = []

    while response.results.results.length.positive?
      response = Doi.query(query, { page: { size: 1000, cursor: cursor } })
      break if response.results.results.length.zero?

      cursor = response.results.to_a.last[:sort]
      search_dois = response.results.results.map(&:doi)
      puts(search_dois)
      dois = DataciteDoi.where(doi: search_dois)

      dois.each do |doi|
        puts(doi.to_jsonapi)
        # send_import_message(doi.to_jsonapi)
      end
    end

    puts("#{response.results.total} NIFS DOIs processed for event creation")
  end
end
