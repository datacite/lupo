# frozen_string_literal: true

namespace :enrichment do
  desc "Process JSONL from S3 and enqueue batches sized by bytes (256KB message size limit)"
  # "Example command: bundle exec rake enrichment:batch_process_file KEY=02022026_test_ingestion_file.jsonl
  # bundle exec rake enrichment:batch_process_file KEY=preprint_matching_enrichments_datacite_format_1000.jsonl
  task batch_process_file: :environment do
    bucket = ENV["ENRICHMENTS_INGESTION_FILES_BUCKET_NAME"]
    key    = ENV["KEY"]

    abort("ENRICHMENTS_INGESTION_FILES_BUCKET_NAME is not set") if bucket.blank?
    abort("KEY is not set") if key.blank?

    # SQS limit is 256KB so we'll set the batch size to be more conservative to allow for some
    # overhead and ensure we don't exceed limits.
    max_batch_bytes = 150000

    puts("Begin ingestion for s3://#{bucket}/#{key} (max_batch_bytes=#{max_batch_bytes})")

    s3 = Aws::S3::Client.new(force_path_style: true)

    buffer  = +""
    line_no = 0

    batch_lines = []
    batch_bytes = 0

    flush = lambda do
      return if batch_lines.empty?

      EnrichmentBatchProcessJob.perform_later(batch_lines, key)

      batch_lines.clear
      batch_bytes = 0
    end

    s3.get_object(bucket: bucket, key: key) do |chunk|
      buffer << chunk

      while (idx = buffer.index("\n"))
        raw = buffer.slice!(0..idx).delete_suffix("\n")
        line_no += 1

        line = raw.strip

        next if line.empty?

        # +1 for the newline we removed, and some slack for JSON array encoding.
        line_bytes = line.bytesize + 1

        # If a single line is too big to ever fit in one message we need to process differently.
        if line_bytes > max_batch_bytes
          raise "Single JSONL line at #{line_no} is #{line_bytes} bytes, exceeds MAX_BATCH_BYTES=#{max_batch_bytes}. "
        end

        # If adding this line would exceed the cap, flush current batch first.
        if (batch_bytes + line_bytes) > max_batch_bytes
          flush.call
        end

        batch_lines << line
        batch_bytes += line_bytes
      end
    end

    # File might not end with newline
    tail = buffer.strip

    unless tail.empty?
      line_no += 1
      line_bytes = tail.bytesize + 1

      if line_bytes > max_batch_bytes
        raise "Single JSONL tail line at #{line_no} is #{line_bytes} bytes, exceeds MAX_BATCH_BYTES=#{max_batch_bytes}."
      end

      flush.call if (batch_bytes + line_bytes) > max_batch_bytes
      batch_lines << tail
      batch_bytes += line_bytes
    end

    flush.call
    puts("Finished ingestion for s3://#{bucket}/#{key} (lines_seen=#{line_no})")
  end
end
