# frozen_string_literal: true

require Rails.root.join("app/services/ror_mapping_loader")

if defined?(Shoryuken) && ENV["DISABLE_QUEUE_WORKER"].blank?
  require "aws-sdk-s3"
  require "fileutils"

  RorMappingLoader.load!
end
