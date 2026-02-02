# frozen_string_literal: true

namespace :enrichment do
  desc "Ingest Enrichment File from S3"
  task ingest_file: :environment do
    bucket = ENV["ENRICHMENTS_INGESTION_FILES_BUCKET_NAME"]
    key = ENV["KEY"]

    if bucket.blank?
      puts("bucket environment variable is not set")
      exit
    end

    if key.blank?
      puts("bucket environment variable is not set")
      exit
    end

    s3 = AWS::S3::Client.new

    buffer = +""

    s3.get_object(bucket: bucket, key: key) do |chunk|
      buffer << chunk

      # Consume complete lines from buffer
      while (newline_index = buffer.index("\n"))
        # Read line
        line = buffer.slice!(0..newline_index)

        # Remove the newline character at the end of line
        line = line.strip

        # Exit the loop, if this line is empty
        next if line.empty?

        puts(line)

        # # Parse the enrichment record to json
        # enrichment = JSON.parse(line)

        # # Queue up the job that processes the record
        # enrichment_process_job.perform_later(enrichment)
      end
    end
  end
end
