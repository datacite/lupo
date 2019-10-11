class Person
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    orcid = orcid_from_url(id)
    return {} unless orcid.present?

    url = "https://api.datacite.org/users/#{orcid}"
    response = Maremma.get(url, host: true)

    return {} if response.status != 200 || response.body.dig("data", "id") != orcid
    
    message = response.body.dig("data", "attributes")
    data = [parse_message(id: id, message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options={})
    limit ||= 25
    page ||= 1

    params = {
      query: query,
      subject: options[:subject],
      "page[size]" => limit,
      "page[number]" => page }.compact

    url = "https://api.datacite.org/users?" + URI.encode_www_form(params)

    response = Maremma.get(url, host: true)

    return [] if response.status != 200
    
    data = Array.wrap(response.body.fetch("data", nil)).map do |message|
      parse_message(id: orcid_as_url(message["id"]), message: message["attributes"])
    end
    meta = { "total" => response.body.dig("meta", "total") }
    errors = response.body.fetch("errors", nil)

    { data: data, meta: meta, errors: errors }
  end

  def self.parse_message(id: nil, message: nil)
    Hashie::Mash.new({
      id: id,
      orcid: message["orcid"],
      name: message["name"],
      given_names: message["givenNames"],
      family_name: message["familyName"] })
  end

  def self.orcid_as_url(orcid)
    return nil unless orcid.present?

    "https://orcid.org/#{orcid}"
  end

  def self.orcid_from_url(url)
    if /\A(?:(http|https):\/\/(orcid.org)\/)(.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end
end
