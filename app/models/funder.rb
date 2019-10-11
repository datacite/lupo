class Funder
  # include helper module for PORO models
  include Modelable

  def self.find_by_id(id)
    doi = doi_from_url(id)
    return [] unless doi.present?

    url = "https://api.crossref.org/funders/#{doi}"
    response = Maremma.get(url, host: true)

    return {} if response.status != 200
    
    message = response.body.dig("data", "message")
    data = [parse_message(id: id, message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options={})
    rows = options[:limit] || 100

    if query.present?
      url = "https://api.crossref.org/funders?query=#{query}&rows=#{rows}"
    else
      url = "https://api.crossref.org/funders?rows=#{rows}"
    end

    response = Maremma.get(url, host: true)

    return {} if response.status != 200

    data = response.body.dig("data", "message", "items").map do |message|
      parse_message(id: "https://doi.org/10.13039/#{message['id']}", message: message)
    end
    meta = { "total" => response.body.dig("data", "message", "total-results") }
    errors = response.body.fetch("errors", nil)

    { data: data, meta: meta, errors: errors }
  end

  def self.parse_message(id: nil, message: nil)
    if message["location"].present?
      c = ISO3166::Country.find_country_by_name(message["location"])
      code = c.present? ? c.alpha2 : nil
      country = {
        "code" => code,
        "name" => message["location"]
      }
    else
      country = nil
    end
    
    Hashie::Mash.new({
      id: id,
      name: message["name"],
      alternate_name: message["alt-names"],
      country: country,
      date_modified: "2019-04-18T00:00:00Z" })
  end
end
