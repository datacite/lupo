# frozen_string_literal: true

# Helpers for the embedded MDS (legacy Metadata Store) protocol surface.
module Mds
  module_function

  def enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("MDS_ENABLED", "false"))
  end

  def hosts
    ENV.fetch("MDS_HOSTS", "").split(",").map { |h| h.strip.downcase }.reject(&:blank?)
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
