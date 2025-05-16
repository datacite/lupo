# frozen_string_literal: true

Aws.config.update({
  region: ENV["AWS_REGION"],
  access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  s3: {
    endpoint: ENV["AWS_ENDPOINT_URL_S3"] || ENV["AWS_ENDPOINT_URL"],
    access_key_id: ENV["AWS_ACCESS_KEY_ID_S3"] || ENV["AWS_ACCESS_KEY_ID"],
    secret_access_key: ENV["AWS_SECRET_ACCESS_KEY_S3"] || ENV["AWS_SECRET_ACCESS_KEY"],
    force_path_style: true
  },
})
