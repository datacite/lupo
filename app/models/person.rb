class Person
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    orcid = orcid_from_url(id)
    return {} unless orcid.present?

    url = "https://pub.orcid.org/v3.0/#{orcid}/person"
    response = Maremma.get(url, accept: "json")
    return {} if response.status != 200 #|| response.body.dig("data", "orcid-identifier", "path") != orcid
    
    message = response.body.dig("data")
    message = {
      "orcid-id" => message.dig("name", "path"),
      "given-names" => message.dig("name", "given-names", "value"),
      "family-names" => message.dig("name", "family-name", "value"),
      "other-name" => message.dig("name", "other-names", "other-name"),
      "credit-name" => message.dig("name", "credit-name", "value"),
    }
    
    data = [parse_message(message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options={})
    options[:rows] ||= 25
    options[:start] ||= 1

    params = {
      q: query,
      "rows" => options[:rows],
      "start" => options[:start] }.compact

    url = "https://pub.orcid.org/v3.0/expanded-search/?" + URI.encode_www_form(params)

    response = Maremma.get(url, accept: "json")

    return [] if response.status != 200
    
    data = Array.wrap(response.body.dig("data", "expanded-result")).map do |message|
      parse_message(message: message)
    end
    meta = { "total" => response.body.dig("data", "num-found").to_i }
    errors = response.body.fetch("errors", nil)

    { data: data, meta: meta, errors: errors }
  end

  def self.parse_message(message: nil)
    orcid = message.fetch("orcid-id", nil)
    given_name = message.fetch("given-names", nil)
    family_name = message.fetch("family-names", nil)
    alternate_name = Array.wrap(message.fetch("other-name", nil))
    if message.fetch("credit-name", nil).present?
      name = message.fetch("credit-name")
    elsif given_name.present? || family_name.present?
      name = [given_name, family_name].join(" ")
    else
      name = orcid
    end
    # TODO affiliation for find_by_id
    affiliation = Array.wrap(message.fetch("institution-name", nil)).map { |a| { name: a } }.compact

    Hashie::Mash.new({
      id: orcid_as_url(orcid),
      type: "Person",
      orcid: orcid,
      given_name: given_name,
      family_name: family_name,
      alternate_name: alternate_name,
      name: name,
      affiliation: affiliation }.compact)
  end
end
