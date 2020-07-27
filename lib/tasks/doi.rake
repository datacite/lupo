# frozen_string_literal: true

namespace :doi do
  desc "Create alias for dois"
  task :create_alias => :environment do
    puts Doi.create_alias
  end

  desc "Delete alias for dois"
  task :delete_alias => :environment do
    puts Doi.delete_alias
  end

  desc 'Store handle URL'
  task :set_url => :environment do
    puts Doi.set_url
  end

  desc 'Set handle'
  task :set_handle => :environment do
    puts Doi.set_handle
  end

  desc 'Set minted'
  task :set_minted => :environment do
    puts Doi.set_minted
  end

  desc "Set schema version"
  task set_schema_version: :environment do
    options = {
      query: "+aasm_state:(findable OR registered) -schema_version:*",
      label: "[SetSchemaVersion]",
      job_name: "SchemaVersionJob",
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set registration agency"
  task set_registration_agency: :environment do
    options = {
      query: "agency:DataCite OR agency:Crossref",
      label: "[SetRegistrationAgency]",
      job_name: "UpdateDoiJob",
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set license"
  task set_license: :environment do
    options = {
      query: "rights_list:* AND -rights_list.rightsIdentifier:*",
      label: "[SetLicense]",
      job_name: "UpdateDoiJob",
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set language"
  task set_language: :environment do
    options = {
      query: "language:*",
      label: "[SetLanguage]",
      job_name: "UpdateDoiJob",
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set identifiers"
  task set_identifiers: :environment do
    options = {
      query: "identifiers.identifierType:DOI",
      label: "[SetIdentifiers]",
      job_name: "UpdateDoiJob",
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set field of science"
  task set_field_of_science: :environment do
    options = {
      query: "subjects.subjectScheme:FOR",
      label: "[SetFieldOfScience]",
      job_name: "UpdateDoiJob",
    }
    puts Doi.loop_through_dois(options)
  end

  desc "Set types"
  task set_types: :environment do
    options = {
      query: "types.resourceTypeGeneral:* AND -types.schemaOrg:*",
      label: "[SetTypes]",
      job_name: "UpdateDoiJob",
    }
    Doi.loop_through_dois(options)
  end

  desc 'Convert affiliations to new format'
  task :convert_affiliations => :environment do
    from_id = (ENV['FROM_ID'] || Doi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Doi.maximum(:id)).to_i

    puts Doi.convert_affiliations(from_id: from_id, until_id: until_id)
  end

  desc 'Convert containers to new format'
  task :convert_containers => :environment do
    from_id = (ENV['FROM_ID'] || Doi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Doi.maximum(:id)).to_i

    puts Doi.convert_containers(from_id: from_id, until_id: until_id)
  end

  desc 'Migrates landing page data handling camelCase changes at same time'
  task :migrate_landing_page => :environment do
    puts Doi.migrate_landing_page
  end

  desc 'Perform repairs on landing page data for specific DOI'
  task :repair_landing_page => :environment do
    if ENV['ID'].nil?
      puts "ENV['ID'] is required"
      exit
    end

    puts Doi.repair_landing_page(id: ENV['ID'])
  end

  desc 'Delete dois by a prefix'
  task :delete_by_prefix => :environment do
    if ENV['PREFIX'].nil?
      puts "ENV['PREFIX'] is required."
      exit
    end

    puts "Note: This does not delete any associated prefix."

    count = Doi.delete_dois_by_prefix(ENV['PREFIX'])
    puts "#{count} DOIs with prefix #{ENV['PREFIX']} deleted."
  end
end
