# frozen_string_literal: true

namespace :enrichment do
  desc "Create index for enriched dois"
  task create_index: :environment do
    puts EnrichedDoi.create_index(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Delete index for enriched dois"
  task delete_index: :environment do
    puts EnrichedDoi.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for enriched dois"
  task upgrade_index: :environment do
    puts EnrichedDoi.upgrade_index
  end

  desc "Create alias for enriched dois"
  task create_alias: :environment do
    puts EnrichedDoi.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Switch index for enriched dois"
  task switch_index: :environment do
    puts EnrichedDoi.switch_index(alias: ENV["ALIAS"], index: ENV["INDEX"])
  end

  desc "Return active index for enriched dois"
  task active_index: :environment do
    puts EnrichedDoi.active_index + " is the active index."
  end

  desc "Create template for enriched dois"
  task create_template: :environment do
    puts EnrichedDoi.create_template
  end

  desc "Process gzipped JSONL objects under an S3 prefix and enqueue batches sized by bytes (256KB message size limit)"
  # Bucket is always ENRICHMENTS_INGESTION_FILES_BUCKET_NAME (enrichments-ingestion-files).
  # PREFIX is the key prefix inside that bucket, e.g. affiliations/2026-09-01/full
  # Example: bundle exec rake enrichment:batch_process_file PREFIX=affiliations/2026-09-01/full
  task batch_process_file: :environment do
    require "zlib"

    bucket = ENV["ENRICHMENTS_INGESTION_FILES_BUCKET_NAME"]
    prefix = ENV["PREFIX"]

    abort("ENRICHMENTS_INGESTION_FILES_BUCKET_NAME is not set") if bucket.blank?
    abort("PREFIX is not set (e.g. affiliations/2026-09-01/full)") if prefix.blank?

    prefix = "#{prefix}/" unless prefix.end_with?("/")

    # SQS limit is 256KB so we'll set the batch size to be more conservative to allow for some
    # overhead and ensure we don't exceed limits.
    max_batch_bytes = 150000

    s3 = Aws::S3::Client.new(force_path_style: true)

    puts("Listing s3://#{bucket}/#{prefix}")

    object_keys = []
    token = nil

    loop do
      response = s3.list_objects_v2(
        bucket: bucket,
        prefix: prefix,
        continuation_token: token,
      )

      Array(response.contents).each do |object|
        object_keys << object.key
      end

      break unless response.is_truncated

      token = response.next_continuation_token
    end

    object_keys.sort!
    abort("No .jsonl.gz objects found at s3://#{bucket}/#{prefix}") if object_keys.empty?

    object_keys.each do |object_key|
      puts("Found object: s3://#{bucket}/#{object_key}")
    end

    process_object = lambda do |object_key|
      puts("Begin ingestion for s3://#{bucket}/#{object_key} (max_batch_bytes=#{max_batch_bytes})")

      buffer = +""
      line_no = 0
      batch_lines = []
      batch_bytes = 0
      inflater = Zlib::Inflate.new(Zlib::MAX_WBITS + 16)

      flush = lambda do
        return if batch_lines.empty?

        # EnrichmentBatchProcessJob.perform_later(batch_lines.dup, object_key)
        batch_lines.dup.each { |x| puts("Processing line: #{x}") }
        batch_lines.clear
        batch_bytes = 0
      end

      enqueue_line = lambda do |raw|
        line = raw.strip
        return if line.empty?

        line_no += 1
        line_bytes = line.bytesize + 1

        if line_bytes > max_batch_bytes
          raise "Single JSONL line at #{object_key}:#{line_no} is #{line_bytes} bytes, exceeds MAX_BATCH_BYTES=#{max_batch_bytes}."
        end

        flush.call if (batch_bytes + line_bytes) > max_batch_bytes

        batch_lines << line
        batch_bytes += line_bytes
      end

      consume_chunk = lambda do |chunk|
        next if chunk.empty?

        buffer << chunk

        while (idx = buffer.index("\n"))
          enqueue_line.call(buffer.slice!(0..idx).delete_suffix("\n"))
        end
      end

      begin
        s3.get_object(bucket: bucket, key: object_key) do |chunk|
          consume_chunk.call(inflater.inflate(chunk))
        end
        consume_chunk.call(inflater.finish)
      ensure
        inflater.close
      end

      enqueue_line.call(buffer) unless buffer.strip.empty?
      flush.call
      puts("Finished ingestion for s3://#{bucket}/#{object_key} (lines_seen=#{line_no})")
    end

    puts("Ingesting #{object_keys.size} gzipped file(s) under s3://#{bucket}/#{prefix}")
    object_keys.each { |object_key| process_object.call(object_key) }
  end

  desc "Process DOI text file from S3"
  # Example command: bundle exec rake enrichment:process_doi_file KEY=arxiv_dois.txt
  task process_doi_file: :environment do
    bucket = ENV["ENRICHMENTS_INGESTION_FILES_BUCKET_NAME"]
    key = ENV["KEY"]

    abort("ENRICHMENTS_INGESTION_FILES_BUCKET_NAME is not set") if bucket.blank?
    abort("KEY is not set") if key.blank?

    puts("Begin enriched doi indexing for s3://#{bucket}/#{key}")

    s3 = Aws::S3::Client.new(force_path_style: true)

    buffer = +""
    line_no = 0

    process_doi = lambda do |doi, current_line_no|
      return if doi.empty?

      puts("Processing DOI [#{current_line_no}]: #{doi}")

      source_doi = Doi.includes(:enrichments).find_by(doi: doi, agency: "datacite")

      if source_doi.blank?
        puts("DOI not found in database: #{doi}")
        return
      end

      EnrichedDoiIndexJob.perform_later(doi)
    end

    s3.get_object(bucket: bucket, key: key) do |chunk|
      buffer << chunk

      while (newline_index = buffer.index("\n"))
        raw_line = buffer.slice!(0..newline_index).delete_suffix("\n")
        line_no += 1

        doi = raw_line.strip
        process_doi.call(doi, line_no)
      end
    end

    # Process final line if file does not end with a newline
    tail = buffer.strip
    unless tail.empty?
      line_no += 1
      process_doi.call(tail, line_no)
    end

    puts("Finished indexing enriched dois for s3://#{bucket}/#{key} (lines_seen=#{line_no})")
  end

  desc "Update source_id for filename"
  # Example command: bundle exec rake enrichment:update_source_id FILENAME=arxiv_dois.txt SOURCE_ID=DATACITE.COMET
  task update_source_id: :environment do
    filename = ENV["FILENAME"]
    source_id = ENV["SOURCE_ID"]&.strip&.upcase

    abort("FILENAME is not set") if filename.blank?
    abort("SOURCE_ID is not set") if source_id.blank?

    enrichments = Enrichment.where(filename: filename)
    total = enrichments.count
    updated = 0

    puts("Updating source_id to #{source_id} for #{total} enrichments with filename=#{filename}")

    enrichments.in_batches(of: 10_000) do |batch|
      count = batch.update_all(source_id: source_id)
      updated += count
      puts("Updated #{updated}/#{total} enrichments")
    end

    puts("Finished updating source_id for filename=#{filename} (updated=#{updated})")
  end
end
