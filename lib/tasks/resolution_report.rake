# frozen_string_literal: true

# lib/tasks/resolution_report.rake

require "aws-sdk-s3"
require "zlib"
require "oj"

#### Command line examples:
## Dry-run examples (defaults to development / LocalStack):
# bundle exec rake "resolution_report:print_prefix_reports[local-resolution-logs,202608/2026-08-prefix-summaries.json.gz,5]"
# bundle exec rake "resolution_report:print_prefix_reports[local-resolution-logs,202608/2026-08-prefix-summaries.json.gz]"

## Dry-run examples (staging / AWS):
# bundle exec rake "resolution_report:print_prefix_reports[resolution-logs-bucket.stage.datacite.org,202608/2026-08-prefix-summaries.json.gz,5,staging]"
# bundle exec rake "resolution_report:print_prefix_reports[resolution-logs-bucket.stage.datacite.org,202608/2026-08-prefix-summaries.json.gz,,staging]"

## Import examples (defaults to development / LocalStack):
# bundle exec rake "resolution_report:import_prefix_reports[local-resolution-logs,202608/2026-08-prefix-summaries.json.gz,5]"
# bundle exec rake "resolution_report:import_prefix_reports[local-resolution-logs,202608/2026-08-prefix-summaries.json.gz]"

## Import examples (staging / AWS):
# bundle exec rake "resolution_report:import_prefix_reports[resolution-logs-bucket.stage.datacite.org,202608/2026-08-prefix-summaries.json.gz,5,staging]"
# bundle exec rake "resolution_report:import_prefix_reports[resolution-logs-bucket.stage.datacite.org,202608/2026-08-prefix-summaries.json.gz,,staging]"

namespace :resolution_report do
  class LimitReached < StandardError; end

  class PrefixReportHandler < Oj::ScHandler
    attr_reader :metadata

    def initialize(&on_prefix_report)
      @on_prefix_report = on_prefix_report
      @stack = []
      @current_key = nil
      @metadata = nil
    end

    def hash_start
      @stack.push({ type: :hash, key: @current_key })
      @current_key = nil
      {}
    end

    def hash_end
      @stack.pop
    end

    def hash_key(key)
      @current_key = key
    end

    def hash_set(h, key, value)
      @metadata = value if @stack.size == 1 && key == "reportMetadata"
      h[key] = value
    end

    def array_start
      @stack.push({ type: :array, key: @current_key })
      @current_key = nil
      []
    end

    def array_end
      @stack.pop
    end

    def array_append(a, value)
      current = @stack.last
      if @stack.size == 2 && current[:type] == :array && current[:key] == "prefixReports"
        @on_prefix_report.call(value)
      else
        a << value
      end
    end
  end

  def self.build_s3_client(env)
    case env.to_s
    when "development"
      Aws::S3::Client.new(
        region: "us-east-1",
        endpoint: "http://localstack:4566",
        access_key_id: "test",
        secret_access_key: "test",
        force_path_style: true
      )
    when "staging", "production"
      Aws::S3::Client.new(
        region: ENV.fetch("AWS_REGION", "eu-west-1")
      )
    else
      abort "Error: Unsupported env '#{env}'. Allowed values: development, staging, production."
    end
  end

  def self.stream_prefix_reports(bucket:, key:, limit: nil, env: "development")
    if bucket.blank? || key.blank?
      abort "Error: bucket and key arguments are required."
    end

    if limit && limit <= 0
      abort "Error: limit must be a positive integer."
    end

    s3 = build_s3_client(env)

    read_io, write_io = IO.pipe
    read_io.binmode
    write_io.binmode

    stop_requested = false

    downloader = Thread.new do
      Thread.current.report_on_exception = false
      s3.get_object(bucket: bucket, key: key) do |chunk|
        break if stop_requested
        write_io.write(chunk)
      end
    rescue IOError, Errno::EPIPE, Aws::S3::Plugins::NonRetryableStreamingError
      raise unless stop_requested
    rescue => e
      warn "\nS3 download error: #{e.message}"
      raise
    ensure
      write_io.close unless write_io.closed?
    end

    count = 0
    metadata = nil

    begin
      Zlib::GzipReader.wrap(read_io) do |gz|
        handler = PrefixReportHandler.new do |prefix_report|
          count += 1
          yield(prefix_report, handler.metadata, count)

          if limit && count >= limit
            metadata = handler.metadata
            raise LimitReached
          end
        end

        Oj.sc_parse(handler, gz)
        metadata = handler.metadata
      end
    rescue LimitReached
      stop_requested = true
      puts "\nStopped early after #{limit} prefixReports."
    ensure
      stop_requested = true
      read_io.close unless read_io.closed?
      downloader.join
    end

    [count, metadata]
  end

  desc "Dry-run: Stream a .json.gz file from S3 and print prefixReports to stdout"
  task :print_prefix_reports, [:bucket, :key, :limit, :env] => :environment do |_t, args|
    args.with_defaults(env: "development")
    limit = args[:limit].present? ? args[:limit].to_i : nil

    count, metadata = stream_prefix_reports(
      bucket: args[:bucket],
      key: args[:key],
      limit: limit,
      env: args[:env]
    ) do |prefix_report, _meta, index|
      puts "--- Prefix Report ##{index} (#{prefix_report['prefix']}) ---"
      puts JSON.pretty_generate(prefix_report)
    end

    puts "Report Metadata: #{metadata.inspect}" if metadata
    puts "Finished printing #{count} prefixReports."
  end

  desc "Import: Stream a .json.gz file from S3 and upsert prefixReports into resolution_reports"
  task :import_prefix_reports, [:bucket, :key, :limit, :env] => :environment do |_t, args|
    args.with_defaults(env: "development")
    limit = args[:limit].present? ? args[:limit].to_i : nil
    batch_size = 1000
    batch = []
    total_upserted = 0
    now = Time.current

    flush_batch = lambda do
      next if batch.empty?

      ResolutionReport.upsert_all(
        batch,
        update_only: %i[
          total_attempted_resolutions
          successful_resolutions
          failed_resolutions
          total_unique_dois
          unique_doi_successes
          unique_doi_failures
          updated_at
        ]
      )
      total_upserted += batch.size
      print "\rUpserted #{total_upserted} records..."
      batch.clear
    end

    stream_prefix_reports(
      bucket: args[:bucket],
      key: args[:key],
      limit: limit,
      env: args[:env]
    ) do |prefix_report, meta, _index|
      period = meta&.fetch("period", nil)
      abort "\nError: reportMetadata.period was not found before prefixReports." if period.blank?

      metrics = prefix_report["summaryMetrics"] || {}

      batch << {
        period: period,
        prefix: prefix_report["prefix"],
        total_attempted_resolutions: metrics["totalAttemptedResolutions"],
        successful_resolutions: metrics["successfulResolutions"],
        failed_resolutions: metrics["failedResolutions"],
        total_unique_dois: metrics["totalUniqueDois"],
        unique_doi_successes: metrics["uniqueDoiSuccesses"],
        unique_doi_failures: metrics["uniqueDoiFailures"],
        created_at: now,
        updated_at: now
      }

      flush_batch.call if batch.size >= batch_size
    end

    flush_batch.call
    puts "\nFinished! Total records upserted: #{total_upserted}"
  end
end
