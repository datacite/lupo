# frozen_string_literal: true

require_relative "mds/error"

# Helpers for the embedded MDS (legacy Metadata Store) protocol surface.
module Mds
  # Production-like hosts when MDS_HOSTS is unset (e.g. production with only MDS_ENABLED=true).
  DEFAULT_HOSTS = %w[
    mds.datacite.org
    mds.test.datacite.org
    mds.stage.datacite.org
    mds.local
  ].freeze

  module_function

  def enabled?
    # Default off unless explicitly enabled (production-safe).
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("MDS_ENABLED", "false"))
  end

  def hosts
    raw = ENV["MDS_HOSTS"].to_s
    list =
      if raw.blank?
        DEFAULT_HOSTS
      else
        raw.split(",").map { |h| h.strip.downcase }.reject(&:blank?)
      end
    list
  end

  def host_match?(request)
    return false unless enabled?

    hosts.include?(request.host.to_s.downcase)
  end

  def url
    ENV.fetch("MDS_URL", "https://mds.test.datacite.org")
  end

  def realm
    ENV.fetch("MDS_REALM", "mds.datacite.org")
  end
end
