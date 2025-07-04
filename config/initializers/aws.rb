# frozen_string_literal: true

aws_config = {
  region: ENV["AWS_REGION"],
  s3: {
    endpoint: ENV["AWS_ENDPOINT_URL_S3"] || ENV["AWS_ENDPOINT_URL"],
    credentials: Aws::Credentials.new(
      ENV["AWS_ACCESS_KEY_ID_S3"] || ENV["AWS_ACCESS_KEY_ID"],
      ENV["AWS_SECRET_ACCESS_KEY_S3"] || ENV["AWS_SECRET_ACCESS_KEY"]
    ),
    force_path_style: true
  },
  sqs: {
    credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"]),
  }
}

if Rails.env.test?
  aws_config[:sqs] = {
    credentials: Aws::Credentials.new("DUMMY_ACCESS_KEY_ID", "DUMMY_SECRET_ACCESS_KEY"),
  }
  aws_config["stub_responses"] = true
end

Aws.config.update(aws_config)
