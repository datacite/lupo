class UrlJob < ActiveJob::Base
  queue_as :lupo

  # retry_on ActiveRecord::Deadlocked, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  def perform(doi_id)
    doi = Doi.where(doi: doi_id).first

    if doi.present?
      response = Doi.get_doi(doi: doi.doi, agency: doi.agency)
      url = response.is_a?(String) ? nil : response.body.dig('data', 'values', 0, 'data', 'value')
      if url.present?
        if (doi.is_registered_or_findable? || %w(europ).include?(doi.provider_id)) && doi.minted.blank?
          doi.update_attributes(url: url, minted: Time.zone.now)
        else
          doi.update_attributes(url: url)
        end

        doi.update_attributes(aasm_state: "findable") if doi.type == "OtherDoi"

        doi.__elasticsearch__.index_document

        Rails.logger.info "[Handle] URL #{url} set for DOI #{doi.doi}." unless Rails.env.test?
      else
        Rails.logger.info "[Handle] Error updating URL for DOI #{doi.doi}: URL not found." unless Rails.env.test?
      end
    else
      Rails.logger.info "[Handle] Error updating URL for DOI #{doi_id}: DOI not found" unless Rails.env.test?
    end
  end
end
