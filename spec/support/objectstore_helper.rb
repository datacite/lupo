# frozen_string_literal: true

require "aws-sdk-s3"

def clean_bucket
  puts("Clearing metadata bucket")
  bucket_name = ENV["METADATA_STORAGE_BUCKET_NAME"]
  s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
  bucket = s3.bucket(bucket_name)
  bucket.objects.batch_delete!

  # Delete the bucket
  puts("Deleting metadata bucket")
  bucket.delete
end

def create_bucket
  puts("Creating metadata bucket")
  bucket_name = ENV["METADATA_STORAGE_BUCKET_NAME"]
  s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
  s3.create_bucket(bucket: bucket_name)

rescue Aws::Errors::ServiceError => e
  puts("Can't create bucket: #{e.message}")
end

RSpec.configure do |config|
  config.before(:suite) do
    unless ENV["METADATA_STORAGE_BUCKET_NAME"].blank?
      create_bucket
    end
  end

  config.after(:suite) do
    unless ENV["METADATA_STORAGE_BUCKET_NAME"].blank?
      clean_bucket
    end
  end
end
