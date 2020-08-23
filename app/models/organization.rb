class Organization
  def self.find_by_id(id)
    ror_id = ror_id_from_url(id)
    return {} unless ror_id.present?

    url = "https://api.ror.org/organizations/#{ror_id}"
    response = Maremma.get(url, host: true)

    return {} if response.status != 200
    
    message = response.body.fetch("data", {})
    data = [parse_message(id: id, message: message)]

    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.query(query, options={})
    # rows = options[:limit] || 20
    page = options[:offset] || 1
    types = options[:types]
    country = options[:country]

    url = "https://api.ror.org/organizations?page=#{page}"
    url += "&query=#{query}" if query.present?
    if types.present? && country.present?
      url += "&filter=types:#{types.upcase_first},country.country_code:#{country.upcase}"
    elsif types.present?
      url += "&filter=types:#{types.upcase_first}"
    elsif country.present?
      url += "&filter=country.country_code:#{country.upcase}"
    end

    puts url

    response = Maremma.get(url, host: true)

    return {} if response.status != 200

    data = Array.wrap(response.body.dig("data", "items")).map do |message|
      parse_message(id: message["id"], message: message)
    end

    countries = (Array.wrap(response.body.dig("data", "meta", "countries"))).map do |hsh|
      country = ISO3166::Country[hsh["id"]]

      { "id" => hsh["id"],
        "title" => country.present? ? country.name : hsh["id"],
        "count" => hsh["count"] }
    end

    meta = { 
      "total" => response.body.dig("data", "number_of_results"),
      "types" => response.body.dig("data", "meta", "types"),
      "countries" => countries,
    }.compact

    errors = response.body.fetch("errors", nil)

    {
      data: data, 
      meta: meta, 
      errors: errors }
  end

  def self.parse_message(id: nil, message: nil)
    country = {
      code: message.dig("country", "country_code"),
      name: message.dig("country", "country_name") }.compact

    labels = Array.wrap(message["labels"]).map do |label|
      code = label["iso639"].present? ? label["iso639"].upcase : nil
      {
        code: code,
        name: label["label"] }.compact
    end

    # remove whitespace from isni identifier
    isni = Array.wrap(message.dig("external_ids", "ISNI", "all")).map do |i|
      i.gsub(/ /, "")
    end

    # add DOI prefix to Crossref Funder ID
    fundref = Array.wrap(message.dig("external_ids", "FundRef", "all")).map do |f|
      "10.13039/#{f}"
    end
    
    Hashie::Mash.new({
      id: id,
      type: "Organization",
      types: message["types"],
      name: message["name"],
      aliases: message["aliases"],
      acronyms: message["acronyms"],
      labels: labels,
      links: message["links"],
      wikipedia_url: message["wikipedia_url"],
      country: country,
      isni: isni,
      fundref: fundref,
      wikidata: message.dig("external_ids", "Wikidata", "all"),
      grid: message.dig("external_ids", "GRID", "all") })
  end

  def self.ror_id_from_url(url)
    Array(/\A(http|https):\/\/(ror\.org\/0\w{6}\d{2})\z/.match(url)).last
  end
end
