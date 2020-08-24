class Person
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    orcid = orcid_from_url(id)
    return {} unless orcid.present?

    url = "https://pub.orcid.org/v3.0/#{orcid}/person"
    response = Maremma.get(url, accept: "json")

    if response.status >= 405
      message = response.body.dig("errors", 0, "title", "developer-message") || "Something went wrong in ORCID"
      fail ::Faraday::ClientError, message
    end 

    return {} if response.status != 200
    
    message = response.body.dig("data")

    other_name = Array.wrap(message.dig("other-names", "other-name")).map do |n|
      n["content"]
    end

    researcher_urls = Array.wrap(message.dig("researcher-urls", "researcher-url")).map do |r|
      { "name" => r["url-name"],
        "url"  => r.dig("url", "value") }
    end

    identifiers = Array.wrap(message.dig("external-identifiers", "external-identifier")).map do |i|
      { "identifierType" => i["external-id-type"],
        "identifierUrl"  => i.dig("external-id-url", "value"),
        "identifier"  => i["external-id-value"] }
    end

    message = {
      "orcid-id" => message.dig("name", "path"),
      "credit-name" => message.dig("name", "credit-name", "value"),
      "given-names" => message.dig("name", "given-names", "value"),
      "family-names" => message.dig("name", "family-name", "value"),
      "other-name" => other_name,
      "description" => message.dig("biography", "content"),
      "researcher-urls" => researcher_urls,
      "identifiers" => identifiers,
      "country-code" => message.dig("addresses", "address", 0, "country", "value"),
    }
    
    data = [parse_message(message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options={})
    options[:limit] ||= 25
    options[:offset] ||= 0

    params = {
      q: query || "*",
      "rows" => options[:limit],
      "start" => options[:offset].to_i * options[:limit].to_i }.compact

    url = "https://pub.orcid.org/v3.0/expanded-search/?" + URI.encode_www_form(params)

    response = Maremma.get(url, accept: "json")
    if response.status >= 400
      message = response.body.dig("errors", 0, "title", "developer-message") || "Something went wrong in ORCID"
      fail ::Faraday::ClientError, message
    end 

    return [] if response.status != 200
    
    data = Array.wrap(response.body.dig("data", "expanded-result")).map do |message|
      parse_message(message: message)
    end
    meta = { "total" => response.body.dig("data", "num-found").to_i }
    errors = response.body.fetch("errors", nil)

    { 
      data: data, 
      meta: meta, 
      errors: errors }
  end

  def self.parse_message(message: nil)
    orcid = message.fetch("orcid-id", nil)

    given_name = message.fetch("given-names", nil)
    family_name = message.fetch("family-names", nil)
    alternate_name = Array.wrap(message.fetch("other-name", nil))
    description = message.fetch("description", nil)
    links = message.fetch("researcher-urls", [])
    identifiers = message.fetch("identifiers", [])

    if message.fetch("credit-name", nil).present?
      name = message.fetch("credit-name")
    elsif given_name.present? || family_name.present?
      name = [given_name, family_name].join(" ")
    else
      name = orcid
    end

    if message.fetch("country-code", nil).present?
      c = ISO3166::Country[message.fetch("country-code")]
      country = {
        id: message.fetch("country-code"),
        name: c.present? ? c.name : message.fetch("country-code") }
    else
      country = nil
    end
    
    Hashie::Mash.new({
      id: orcid_as_url(orcid),
      type: "Person",
      orcid: orcid,
      name: name,
      given_name: given_name,
      family_name: family_name,
      alternate_name: alternate_name,
      description: description,
      links: links,
      identifiers: identifiers,
      country: country }.compact)
  end
end
