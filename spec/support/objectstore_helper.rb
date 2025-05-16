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

RSpec.configure do |config|
  config.before(:suite) do
    puts("Creating metadata bucket")

    bucket_name = ENV["METADATA_STORAGE_BUCKET_NAME"]
    s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
    s3.create_bucket(bucket: bucket_name)
  end

  # This is to clean up beteween tests metadata documents stored in the objectstore i.e. minio
  config.after(:suite) do
    clean_bucket
  end
end
