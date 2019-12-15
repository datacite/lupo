class OrcidAutoUpdateByIdJob < ActiveJob::Base
  queue_as :lupo_background

  # retry_on ActiveRecord::Deadlocked, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  def perform(id, options={})
    orcid = orcid_from_url(id)
    return {} unless orcid.present?

    # check whether ORCID ID has been stored with DataCite already
    # unless we want to refresh the metadata
    unless options[:refresh]
      result = Researcher.find_by_id(orcid).results.first
      return {} unless result.blank?
    end

    # otherwise fetch basic ORCID metadata and store with DataCite
    url = "https://pub.orcid.org/v2.1/#{orcid}/person"
    # if Rails.env.production?
    #   url = "https://pub.orcid.org/v2.1/#{orcid}/person"
    # else
    #   url = "https://pub.sandbox.orcid.org/v2.1/#{orcid}/person"
    # end

    response = Maremma.get(url, accept: "application/vnd.orcid+json")
    return {} if response.status != 200

    message = response.body.fetch("data", {})
    attributes = parse_message(message: message)
    data = {
      "data" => {
        "type" => "researchers",
        "attributes" => attributes
      }
    }
    url = "http://localhost/researchers/#{orcid}"
    response = Maremma.put(url, accept: 'application/vnd.api+json', 
                                content_type: 'application/vnd.api+json',
                                data: data.to_json, 
                                username: ENV["ADMIN_USERNAME"],
                                password: ENV["ADMIN_PASSWORD"])

    if [200, 201].include?(response.status)
      Rails.logger.info "ORCID #{orcid} added."
    else
      Rails.logger.error "[Error for ORCID #{orcid}]: " + response.body["errors"].inspect
    end
  end

  def parse_message(message: nil)
    given_names = message.dig("name", "given-names", "value")
    family_name = message.dig("name", "family-name", "value")
    if message.dig("name", "credit-name", "value").present?
      name = message.dig("name", "credit-name", "value")
    elsif given_names.present? || family_name.present?
      name = [given_names, family_name].join(" ")
    else
      name = nil
    end

    {
      "name" => name,
      "givenNames" => given_names,
      "familyName" => family_name }.compact
  end

  def orcid_from_url(url)
    Array(/\A(http|https):\/\/orcid\.org\/(.+)/.match(url)).last
  end
end
