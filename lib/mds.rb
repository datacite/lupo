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

  # Classic MDS plain-text 404 copy differs by resource family.
  DOI_NOT_FOUND = "DOI not found"
  DOI_UNKNOWN_TO_MDS = "DOI is unknown to MDS"
  PATH_BODY_MISMATCH = "doi parameter does not match doi of resource"

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

  # Shared path vs body DOI consistency for PUT /doi and metadata registration.
  def assert_path_matches_body!(path_doi, body_doi)
    return if path_doi.blank? || body_doi.blank?
    return if body_doi.to_s.casecmp(path_doi.to_s).zero?

    raise IdentifierError, PATH_BODY_MISMATCH
  end
end
