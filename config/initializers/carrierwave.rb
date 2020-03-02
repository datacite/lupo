if Rails.env.test?
  CarrierWave.configure do |config|
    config.storage = :file
    config.asset_host = nil
    config.enable_processing = true
    config.ignore_integrity_errors = false
    config.ignore_processing_errors = false
    config.ignore_download_errors = false
  end
else
  CarrierWave.configure do |config|
    config.storage    = :aws
    config.aws_bucket = ENV.fetch('AWS_S3_BUCKET')
    config.asset_host = ENV.fetch('CDN_URL')

    config.enable_processing = true
    config.ignore_integrity_errors = false
    config.ignore_processing_errors = false
    config.ignore_download_errors = false

    config.aws_attributes = -> { {
      expires: 1.week.from_now.httpdate,
      cache_control: 'max-age=604800'
    } }

    config.aws_credentials = {
      access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
      region:            ENV.fetch('AWS_REGION'),
      stub_responses:    Rails.env.test?
    }
  end
end
