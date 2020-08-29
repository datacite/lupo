class Organization
  def self.find_by_id(id)
    ror_id = ror_id_from_url(id)
    return {} unless ror_id.present?

    url = "https://api.ror.org/organizations/#{ror_id}"
    response = Maremma.get(url, host: true)

    return {} if response.status != 200
    
    message = response.body.fetch("data", {})
    data = [parse_message(id: id, message: message)]

    wikidata = data.dig(0, "wikidata", 0)
    wikidata_data = find_by_wikidata_id(wikidata)
    data = [data.first.reverse_merge(wikidata_data[:data].first)] if wikidata_data
    
    errors = response.body.fetch("errors", nil)

    { data: data, errors: errors }
  end

  def self.find_by_wikidata_id(wikidata_id)
    return {} unless wikidata_id.present?

    url = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wikidata_id}&languages=en&props=labels|descriptions|claims&format=json"
    
    response = Maremma.get(url, host: true)

    return {} if response.status != 200
    
    message = response.body.fetch("data", {})
    data = [parse_wikidata_message(id: wikidata_id, message: message)]

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
      wikipedia_url: message["wikipedia_url"].presence,
      country: country,
      isni: isni,
      fundref: fundref,
      wikidata: message.dig("external_ids", "Wikidata", "all"),
      grid: message.dig("external_ids", "GRID", "all") })
  end

  def self.parse_wikidata_message(id: nil, message: nil)
    name = message.dig("entities", id, "labels", "en", "value")
    description = message.dig("entities", id, "descriptions", "en", "value")
    description = description.upcase_first if description.present?

    claims = message.dig("entities", id, "claims") || {}
    twitter = claims.dig("P2002", 0, "mainsnak", "datavalue", "value")
    inception = claims.dig("P571", 0, "mainsnak", "datavalue", "value", "time")
    # remove plus sign at beginning of datetime strings
    inception = inception.gsub(/^\+/, "") if inception.present?
    geolocation = claims.dig("P625", 0, "mainsnak", "datavalue", "value") || 
                  claims.dig("P625", 0, "datavalue", "value") || 
                  claims.dig("P159", 0, "qualifiers", "P625", 0, "datavalue", "value") || {}
    ringgold = claims.dig("P3500", 0, "mainsnak", "datavalue", "value")
    geonames = claims.dig("P1566", 0, "mainsnak", "datavalue", "value") || 
               claims.dig("P1566", 0, "datavalue", "value")

    Hashie::Mash.new({
      id: id,
      type: "Organization",
      name: name,
      description: description,
      twitter: twitter,
      inception: inception,
      geolocation: geolocation.extract!("longitude", "latitude"),
      ringgold: ringgold,
      geonames: geonames }) 
  end

  def self.ror_id_from_url(url)
    Array(/\A(http|https):\/\/(ror\.org\/0\w{6}\d{2})\z/.match(url)).last
  end
end
