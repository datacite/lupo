# frozen_string_literal: true

if defined?(Shoryuken) && ENV["DISABLE_QUEUE_WORKER"].blank?
  require "aws-sdk-s3"
  require "fileutils"

  RorMappingLoader.load!
end
