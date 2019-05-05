class Funder
  def self.find_by_id(id)
    doi = doi_from_url(id)
    return [] unless doi.present?

    url = "https://api.crossref.org/funders/#{doi}"
    response = Maremma.get(url, host: true)

    return [] if response.status != 200
    
    message = response.body.dig("data", "message")
    [parse_message(id: id, message: message)]
  end

  def self.query(query, options={})
    rows = options[:limit] || 100

    if query.present?
      url = "https://api.crossref.org/funders?query=#{query}&rows=#{rows}"
    else
      url = "https://api.crossref.org/funders?rows=#{rows}"
    end

    response = Maremma.get(url, host: true)

    return [] if response.status != 200
    
    items = response.body.dig("data", "message", "items")
    items.map do |message|
      parse_message(id: "https://doi.org/10.13039/#{message['id']}", message: message)
    end
  end

  def self.parse_message(id: nil, message: nil)
    if message["location"].present?
      location = { 
        "country" => message["location"]
      }
    else
      location = nil
    end
    
    {
      id: id,
      name: message["name"],
      alternate_name: message["alt-names"],
      country: message["location"],
      date_modified: "2019-04-18T00:00:00Z" }.compact
  end

  def self.doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, '').downcase
    end
  end
end
