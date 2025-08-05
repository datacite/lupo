# frozen_string_literal: true

namespace :metadata do
  desc "Migrate from stored xml in database to object store (mysql to s3)"
  task migrate_xml: :environment do
    from_id = (ENV["FROM_ID"] || Metadata.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || Metadata.maximum(:id)).to_i

    # Call a function that will move previous versions to S3
    puts Metadata.migrate_xml(from_id, until_id)
  end

  desc "Migrate one record from stored xml in database to object store (mysql to s3)"
  task migrate_xml_one: :environment do
    id = ENV["ID"]

    # Call a function that will move previous versions to S3
    puts Metadata.migrate_xml_by_id(id)
  end
end
