class CrossrefDoiByIdJob < ActiveJob::Base
  queue_as :lupo_background

  # retry_on ActiveRecord::Deadlocked, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  def perform(id)
    logger = Logger.new(STDOUT)

    doi = doi_from_url(id)
    return {} unless doi.present?

    # check whether DOI has been registered with DataCite already
    result = Doi.find_by_id(doi).results.first
    return {} unless result.blank?

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

    if [200, 201].include?(response.status)
      logger.info "DOI #{doi} created."
    else
      logger.warn response.body["errors"]
    end
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, '').downcase
    end
  end
end