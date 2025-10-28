# frozen_string_literal: true

class OtherDoiImportWorker
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_events_other_doi_job" }, auto_delete: true

  def perform(sqs_message = nil, data = nil)
    data_hash = JSON.parse(data)
    dois = dois_to_import(data_hash)
    OtherDoiJob.perform_later(dois_to_import)
  end

  private

  def dois_to_import(data_hash)
    [doi_from_url(data_hash["subj_id"]), doi_from_url(data_hash["obj_id"])].compact.reduce(
      [],
    ) do |sum, d|
      prefix = d.split("/", 2).first

      # ignore Crossref Funder ID
      next sum if prefix == "10.13039"

      # ignore DataCite DOIs
      ra = cached_get_doi_ra(prefix)&.downcase
      next sum if ra.blank? || ra == "datacite"

      sum.push d
      sum
    end
  end
end
