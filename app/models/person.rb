class Person
  # include helper module for PORO models
  include Modelable

  # include helper module for dates
  include Dateable

  def self.find_by_id(id)
    orcid = orcid_from_url(id)
    return {} unless orcid.present?

    person = get_orcid(orcid: orcid, endpoint: "person")
    return {} unless person.present?

    employments = get_orcid(orcid: orcid, endpoint: "employments")

    other_name = Array.wrap(person.dig("data", "other-names", "other-name")).map do |n|
      n["content"]
    end

    researcher_urls = Array.wrap(person.dig("data", "researcher-urls", "researcher-url")).map do |r|
      { "name" => r["url-name"],
        "url"  => r.dig("url", "value") }
    end

    identifiers = Array.wrap(person.dig("data", "external-identifiers", "external-identifier")).map do |i|
      { "identifierType" => i["external-id-type"],
        "identifierUrl"  => i.dig("external-id-url", "value"),
        "identifier"  => i["external-id-value"] }
    end

    employment = Array.wrap(employments.dig("data", "affiliation-group")).map do |a|
      i = a.dig("summaries", 0, "employment-summary", "organization", "disambiguated-organization") || {}
      s = a.dig("summaries", 0, "employment-summary", "start-date") || {}
      e = a.dig("summaries", 0, "employment-summary", "end-date") || {}
      
      { "OrganizationName" => a.dig("summaries", 0, "employment-summary", "organization", "name"),
        "ringgold"  => i.dig("disambiguation-source") == "RINGGOLD" ? i.dig("disambiguated-organization-identifier") : nil,
        "grid"  => i.dig("disambiguation-source") == "GRID" ? i.dig("disambiguated-organization-identifier") : nil,
        "roleTitle" => a.dig("summaries", 0, "employment-summary", "role-title"),
        "startDate" => get_date_from_parts(s.dig("year", "value"), s.dig("month", "value"), s.dig("day", "value")),
        "endDate" => get_date_from_parts(e.dig("year", "value"), e.dig("month", "value"), e.dig("day", "value")) }.compact
    end

    message = {
      "orcid-id" => person.dig("data", "name", "path"),
      "credit-name" => person.dig("data", "name", "credit-name", "value"),
      "given-names" => person.dig("data", "name", "given-names", "value"),
      "family-names" => person.dig("data", "name", "family-name", "value"),
      "other-name" => other_name,
      "description" => person.dig("data", "biography", "content"),
      "researcher-urls" => researcher_urls,
      "identifiers" => identifiers,
      "country-code" => person.dig("data", "addresses", "address", 0, "country", "value"),
      "employment" => wikidata_query(employment),
    }
    
    data = [parse_message(message: message)]

    errors = person.fetch("errors", nil)

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

  def self.get_orcid(orcid: nil, endpoint: nil)
    url = "https://pub.orcid.org/v3.0/#{orcid}/#{endpoint}"
    response = Maremma.get(url, accept: "json")

    if response.status >= 405
      message = response.body.dig("errors", 0, "title", "developer-message") || "Something went wrong in ORCID"
      fail ::Faraday::ClientError, message
    end 

    return {} if response.status != 200
    
    response.body
  end

  def self.parse_message(message: nil)
    orcid = message.fetch("orcid-id", nil)

    given_name = message.fetch("given-names", nil)
    family_name = message.fetch("family-names", nil)
    alternate_name = Array.wrap(message.fetch("other-name", nil))
    description = message.fetch("description", nil)
    links = message.fetch("researcher-urls", [])
    identifiers = message.fetch("identifiers", [])
    employment = message.fetch("employment", [])

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
      country: country,
      employment: employment }.compact)
  end

  # SPARQL query to fetch organizational identifiers from Wikidata
  # PREFIX wikibase: <http://wikiba.se/ontology#>
  # PREFIX wd: <http://www.wikidata.org/entity/> 
  # PREFIX wdt: <http://www.wikidata.org/prop/direct/>
  # PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  # PREFIX p: <http://www.wikidata.org/prop/>
  # PREFIX v: <http://www.wikidata.org/prop/statement/>

  # SELECT ?item ?itemLabel ?ror ?grid ?ringgold WHERE {  
  #   ?item wdt:P6782 ?ror;
  #         wdt:P3500 ?ringgold;
  #         wdt:P2427 ?grid .
  #   FILTER(?ringgold in ("9177", "219874", "14903") || ?grid in ("grid.475826.a")).
  #   SERVICE wikibase:label {
  #     bd:serviceParam wikibase:language "[AUTO_LANGUAGE]" .
  #   }
  # }
  def self.wikidata_query(employment)
    ringgold_filter = Array.wrap(employment).reduce([]) do |sum, f|
      sum << f["ringgold"] if f["ringgold"]

      sum
    end.join("%22%2C%20%22")
    ringgold_filter = "%3Fringgold%20in%20(%22#{ringgold_filter}%22)" if ringgold_filter.present?

    grid_filter = Array.wrap(employment).reduce([]) do |sum, f|
      sum << f["grid"] if f["grid"]

      sum
    end.join("%22%2C%20%22")
    grid_filter = "(%3Fgrid%20in%20(%22#{grid_filter}%22)" if grid_filter.present?
    filter = [ringgold_filter, grid_filter].compact.join("%20%7C%7C%20")

    #filter = "(%3Fringgold%20in%20(%229177%22%2C%20%22219874%22%2C%20%2214903%22)%20%7C%7C%20%3Fgrid%20in%20(%22grid.475826.a%22))"
    url = "https://query.wikidata.org/sparql?query=PREFIX%20wikibase%3A%20%3Chttp%3A%2F%2Fwikiba.se%2Fontology%23%3E%0APREFIX%20wd%3A%20%3Chttp%3A%2F%2Fwww.wikidata.org%2Fentity%2F%3E%20%0APREFIX%20wdt%3A%20%3Chttp%3A%2F%2Fwww.wikidata.org%2Fprop%2Fdirect%2F%3E%0APREFIX%20rdfs%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23%3E%0APREFIX%20p%3A%20%3Chttp%3A%2F%2Fwww.wikidata.org%2Fprop%2F%3E%0APREFIX%20v%3A%20%3Chttp%3A%2F%2Fwww.wikidata.org%2Fprop%2Fstatement%2F%3E%0A%0ASELECT%20%3Fitem%20%3FitemLabel%20%3Fror%20%3Fgrid%20%3Fringgold%20WHERE%20%7B%20%20%0A%20%20%3Fitem%20wdt%3AP6782%20%3Fror%3B%0A%20%20%20%20%20%20%20%20wdt%3AP3500%20%3Fringgold%3B%0A%20%20%20%20%20%20%20%20wdt%3AP2427%20%3Fgrid%20.%0A%20%20FILTER(#{filter})).%0A%20%20SERVICE%20wikibase%3Alabel%20%7B%0A%20%20%20%20bd%3AserviceParam%20wikibase%3Alanguage%20%22%5BAUTO_LANGUAGE%5D%22%20.%0A%20%20%20%7D%0A%7D"
    response = Maremma.get(url, host: true)

    #puts response.body["errors"] if response.status >= 400
    # return [] if response.status != 200

    ringgold_to_ror = Array.wrap(response.body.dig("data", "results", "bindings")).reduce({}) do |sum, r|
      if ror = r.dig("ror", "value") && r.dig("ringgold", "value")
        sum[r.dig("ringgold", "value")] = "https://ror.org/" + r.dig("ror", "value") 
      end

      sum
    end

    grid_to_ror = Array.wrap(response.body.dig("data", "results", "bindings")).reduce({}) do |sum, r|
      if ror = r.dig("ror", "value") && r.dig("grid", "value")
        sum[r.dig("grid", "value")] = "https://ror.org/" + r.dig("ror", "value") 
      end

      sum
    end

    Array.wrap(employment).reduce([]) do |sum, e|
      if ringgold_to_ror[e["ringgold"]]
        e["organizationId"] = ringgold_to_ror[e["ringgold"]]
        e.except!("ringgold", "grid")
        sum << e
      elsif grid_to_ror[e["grid"]]
        e["organizationId"] = grid_to_ror[e["grid"]]
        e.except!("grid", "ringgold")
        sum << e
      end

      sum
    end
  end
end
