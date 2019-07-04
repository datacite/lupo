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

    # otherwise store Crossref metadata with DataCite 
    # using client crossref.citations and DataCite XML
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
              "id" => "crossref.citations"
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
    else
      logger.error "[Error parsing Crossref DOI #{doi}]: " + response.body["errors"].inspect
    end
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, '').downcase
    end
  end
end