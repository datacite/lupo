class OtherDoiByIdJob < ActiveJob::Base
  queue_as :lupo_background

  # retry_on ActiveRecord::Deadlocked, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(id, options={})
    doi = doi_from_url(id)
    return {} unless doi.present?

    # check whether DOI has been stored with DataCite already
    # unless we want to refresh the metadata
    unless options[:refresh]
      result = OtherDoi.find_by_id(doi).results.first
      return {} if result.present?
    end

    # otherwise store DOI metadata with DataCite 
    # check DOI registration agency as Crossref also indexes DOIs from other RAs
    # using DataCite XML
    ra = get_doi_ra(id).downcase
    return {} if ra.blank? || ra == "datacite"

    xml = Base64.strict_encode64(id)

    params = {
      "xml" => xml,
      "source" => "levriero",
      "agency" => ra,
      "event" => "publish" }.compact

    @doi = OtherDoi.new(params)
    if @doi.save
      Rails.logger.info "DOI #{doi} record created."
    else
      Rails.logger.error "[Error saving DOI #{doi} for #{ra}]: " + @doi.errors.messages.inspect
    end
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, '').downcase
    end
  end

  def get_doi_ra(doi)
    prefix = validate_prefix(doi)
    return nil if prefix.blank?

    url = "https://doi.org/ra/#{prefix}"
    result = Maremma.get(url)

    result.body.dig("data", 0, "RA")
  end

  def validate_prefix(doi)
    Array(/\A(?:(http|https):\/(\/)?(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}).*\z/.match(doi)).last
  end
end