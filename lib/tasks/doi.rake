# frozen_string_literal: true

namespace :doi do
  # TODO switch to DataCite DOI index
  desc "Create index for dois"
  task create_index: :environment do
    puts Doi.create_index(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Delete index for dois"
  task delete_index: :environment do
    puts Doi.delete_index(index: ENV["INDEX"])
  end

  desc "List indices for dois"
  task list_indices: :environment do
    puts Doi.list_indices
  end

  desc "Upgrade index for dois"
  task upgrade_index: :environment do
    puts Doi.upgrade_index(index: ENV["INDEX"])
  end

  desc "Create alias for dois"
  task create_alias: :environment do
    puts Doi.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List aliases for dois"
  task list_aliases: :environment do
    puts Doi.list_aliases
  end

  desc "Delete alias for dois"
  task delete_alias: :environment do
    puts Doi.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Show index stats for dois"
  task index_stats: :environment do
    puts Doi.index_stats(active_index: ENV["ACTIVE"], inactive_index: ENV["INACTIVE"])
  end

  desc "Switch index for dois"
  task switch_index: :environment do
    puts Doi.switch_index(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List templates for dois"
  task list_templates: :environment do
    puts Doi.list_templates(name: "dois*")
  end

  desc "Return active index for dois"
  task active_index: :environment do
    puts Doi.active_index + " is the active index."
  end

  desc "Monitor reindexing for dois"
  task monitor_reindex: :environment do
    puts Doi.monitor_reindex
  end

  desc "Delete from index by query"
  task delete_by_query: :environment do
    if ENV["QUERY"].nil?
      puts "ENV['QUERY'] is required"
      exit
    end

    puts Doi.delete_by_query(index: ENV["INDEX"], query: ENV["QUERY"])
  end

  desc "Store handle URL"
  task set_url: :environment do
    puts Doi.set_url
  end

  desc "Set handle"
  task set_handle: :environment do
    puts Doi.set_handle
  end

  desc "Set minted"
  task set_minted: :environment do
    puts Doi.set_minted
  end

  desc "Set schema version"
  task set_schema_version: :environment do
    options = {
      query: "+aasm_state:(findable OR registered) -schema_version:*",
      label: "[SetSchemaVersion]",
      job_name: "SchemaVersionJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set registration agency"
  task set_registration_agency: :environment do
    options = {
      query: "agency:DataCite OR agency:Crossref",
      label: "[SetRegistrationAgency]",
      job_name: "UpdateDoiJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set license"
  task set_license: :environment do
    options = {
      query: "rights_list:* AND -rights_list.rightsIdentifier:*",
      label: "[SetLicense]",
      job_name: "UpdateDoiJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set language"
  task set_language: :environment do
    options = {
      query: "language:*",
      label: "[SetLanguage]",
      job_name: "UpdateDoiJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set identifiers"
  task set_identifiers: :environment do
    options = {
      query: "identifiers.identifierType:DOI",
      label: "[SetIdentifiers]",
      job_name: "UpdateDoiJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set field of science"
  task set_field_of_science: :environment do
    options = {
      query: "subjects.subjectScheme:FOR",
      label: "[SetFieldOfScience]",
      job_name: "UpdateDoiJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set types"
  task set_types: :environment do
    options = {
      query: "types.resourceTypeGeneral:* AND -types.schemaOrg:*",
      label: "[SetTypes]",
      job_name: "UpdateDoiJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    Doi.loop_through_dois(options)
  end

  desc "Trigger DOI update based on query"
  task update_dois_by_query: :environment do
    # Ensure we have specified a query of some kind.
    if ENV["QUERY"].blank?
      puts "ENV['QUERY'] is required"
      exit
    end

    options = {
      query: ENV["QUERY"],
      label: "[UpdateDoiByQuery]",
      job_name: "UpdateDoiJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Import one DOI"
  task import_one: :environment do
    if ENV["DOI"].nil? && ENV["ID"].nil?
      puts "Either ENV variable DOI or ID are required"
      exit
    end

    puts Doi.import_one(doi_id: ENV["DOI"], id: ENV["ID"])
  end

  desc "Trigger DOI import based on query"
  task import_dois_by_query: :environment do
    # Ensure we have specified a query of some kind.
    if ENV["QUERY"].blank?
      puts "ENV['QUERY'] is required"
      exit
    end

    options = {
      query: ENV["QUERY"],
      label: "[ImportDoiByQuery]",
      job_name: "ImportDoiJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Trigger DOI handle registration based on query"
  task register_dois_by_query: :environment do
    # Ensure we have specified a query of some kind.
    if ENV["QUERY"].blank?
      puts "ENV['QUERY'] is required"
      exit
    end

    options = {
      query: ENV["QUERY"],
      label: "[RegisterDoiByQuery]",
      job_name: "HandleJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  # until all Crossref DOIs are indexed as otherDoi
  desc "Refresh metadata"
  task refresh: :environment do
    options = {
      query: ENV["QUERY"],
      label: "[RefreshMetadata]",
      job_name: "DoiRefreshJob",
      cursor: ENV["CURSOR"].present? ? Base64.urlsafe_decode64(ENV["CURSOR"]).split(",", 2) : [],
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Convert affiliations to new format"
  task convert_affiliations: :environment do
    from_id = (ENV["FROM_ID"] || Doi.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || Doi.maximum(:id)).to_i

    puts Doi.convert_affiliations(from_id: from_id, until_id: until_id)
  end

  desc "Convert publishers to new format"
  task convert_publishers: :environment do
    from_id = (ENV["FROM_ID"] || Doi.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || Doi.maximum(:id)).to_i

    puts Doi.convert_publishers(from_id: from_id, until_id: until_id)
  end

  desc "Convert containers to new format"
  task convert_containers: :environment do
    from_id = (ENV["FROM_ID"] || Doi.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || Doi.maximum(:id)).to_i

    puts Doi.convert_containers(from_id: from_id, until_id: until_id)
  end

  desc "Migrates landing page data handling camelCase changes at same time"
  task migrate_landing_page: :environment do
    puts Doi.migrate_landing_page
  end

  desc "Perform repairs on landing page data for specific DOI"
  task repair_landing_page: :environment do
    if ENV["ID"].nil?
      puts "ENV['ID'] is required"
      exit
    end

    puts Doi.repair_landing_page(id: ENV["ID"])
  end

  desc "Delete dois by a prefix"
  task delete_by_prefix: :environment do
    if ENV["PREFIX"].nil?
      puts "ENV['PREFIX'] is required."
      exit
    end

    puts "Note: This does not delete any associated prefix."

    count = Doi.delete_dois_by_prefix(ENV["PREFIX"])
    puts "#{count} DOIs with prefix #{ENV['PREFIX']} deleted."
  end

  desc "HIDE dois by a prefix"
  task hide_by_prefix: :environment do
    if ENV["PREFIX"].nil?
      puts "ENV['PREFIX'] is required."
      exit
    end

    puts "Note: This does not delete any associated prefix."

    count = Doi.hide_dois_by_prefix(ENV["PREFIX"])
    puts "#{count} DOIs with prefix #{ENV['PREFIX']} hidden."
  end

  desc "Delete doi by a doi"
  task delete_by_doi: :environment do
    if ENV["DOI"].nil?
      puts "ENV['DOI'] is required."
      exit
    end

    Doi.delete_by_doi(ENV["DOI"])
    puts "DOI #{ENV['DOI']} will be deleted."
  end

  desc "HIDE doi by a doi"
  task hide_by_doi: :environment do
    if ENV["DOI"].nil?
      puts "ENV['DOI'] is required."
      exit
    end

    Doi.hide_by_doi(ENV["DOI"])
    puts "DOI #{ENV['DOI']} will be hidden (state changed from findable=>registered)."
  end

  desc "Add type information to dois based on id range"
  task add_index_type: :environment do
    options = {
      from_id: ENV["FROM_ID"],
      until_id: ENV["UNTIL_ID"],
    }
    puts Doi.add_index_type(options)
  end
end
