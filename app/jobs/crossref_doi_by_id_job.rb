class CrossrefDoiByIdJob < ActiveJob::Base
  queue_as :lupo_background

  # retry_on ActiveRecord::Deadlocked, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  def perform(id, options={})
    logger = Logger.new(STDOUT)

    doi = doi_from_url(id)
    return {} unless doi.present?

    # check whether DOI has been stored with DataCite already
    # unless we want to refresh the metadata
    unless options[:refresh]
      result = Doi.find_by_id(doi).results.first
      return {} unless result.blank?
    end

    # otherwise store DOI metadata with DataCite 
    # check DOI registration agency as Crossref also indexes DOIs from other RAs
    # using client crossref.citations, medra.citations, etc. and DataCite XML
    ra = get_doi_ra(id).downcase
    return {} unless ra.present?

    client_id = ra.downcase + ".citations"

    xml = Base64.strict_encode64(id)
    attributes = {
      "xml" => xml,
      "source" => "levriero",
      "event" => "publish" }.compact

    data = {
      "data" => {
        "type" => "dois",
        "attributes" => attributes,
        "relationships" => {
          "client" =>  {
            "data" => {
              "type" => "clients",
              "id" => client_id
            }
          }
        }
      }
    }

    url = "http://localhost/dois/#{doi}"
    response = Maremma.put(url, accept: 'application/vnd.api+json', 
                                content_type: 'application/vnd.api+json',
                                data: data.to_json,
                                username: ENV["ADMIN_USERNAME"],
                                password: ENV["ADMIN_PASSWORD"])

    if response.status == 201
      logger.info "DOI #{doi} record created."
    elsif response.status == 200
      logger.info "DOI #{doi} record updated."
    elsif response.status == 404
      logger.warn "[Warn] #{ra} DOI #{doi} not found."
    else
      logger.error "[Error parsing #{ra} DOI #{doi}]: " + response.body["errors"].inspect
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