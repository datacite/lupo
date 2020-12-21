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

  desc "Import all datacite DOIs"
  task import: :environment do
    from_id = (ENV["FROM_ID"] || DataciteDoi.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || DataciteDoi.maximum(:id)).to_i

    puts Doi.import_by_ids(model: "DataciteDoi", from_id: from_id, until_id: until_id, index: ENV["INDEX"] || DataciteDoi.inactive_index)
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
