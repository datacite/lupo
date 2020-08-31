# frozen_string_literal: true

module Wikidatable
  extend ActiveSupport::Concern

  require "sparql/client"

  module ClassMethods
    def find_by_wikidata_id(wikidata_id)
      response = fetch_wikidata_by_id(wikidata_id)
      message = response.fetch("data", {})
      data = [parse_wikidata_message(id: wikidata_id, message: message)]
      errors = response.fetch("errors", nil)
  
      { data: data, errors: errors }
    end

    def fetch_wikidata_by_id(wikidata_id)
      return {} unless wikidata_id.present?
  
      url = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wikidata_id}&languages=en&props=labels|descriptions|claims&format=json"
      
      response = Maremma.get(url, host: true)
  
      return {} if response.status != 200

      response.body
    end

    def parse_wikidata_message(id: nil, message: nil)
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

    def wikidata_query(employment)
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

      url = "https://query.wikidata.org/sparql?query=PREFIX%20wikibase%3A%20%3Chttp%3A%2F%2Fwikiba.se%2Fontology%23%3E%0APREFIX%20wd%3A%20%3Chttp%3A%2F%2Fwww.wikidata.org%2Fentity%2F%3E%20%0APREFIX%20wdt%3A%20%3Chttp%3A%2F%2Fwww.wikidata.org%2Fprop%2Fdirect%2F%3E%0APREFIX%20rdfs%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23%3E%0APREFIX%20p%3A%20%3Chttp%3A%2F%2Fwww.wikidata.org%2Fprop%2F%3E%0APREFIX%20v%3A%20%3Chttp%3A%2F%2Fwww.wikidata.org%2Fprop%2Fstatement%2F%3E%0A%0ASELECT%20%3Fitem%20%3FitemLabel%20%3Fror%20%3Fgrid%20%3Fringgold%20WHERE%20%7B%20%20%0A%20%20%3Fitem%20wdt%3AP6782%20%3Fror%3B%0A%20%20%20%20%20%20%20%20wdt%3AP3500%20%3Fringgold%3B%0A%20%20%20%20%20%20%20%20wdt%3AP2427%20%3Fgrid%20.%0A%20%20FILTER(#{filter})).%0A%20%20SERVICE%20wikibase%3Alabel%20%7B%0A%20%20%20%20bd%3AserviceParam%20wikibase%3Alanguage%20%22%5BAUTO_LANGUAGE%5D%22%20.%0A%20%20%20%7D%0A%7D"
      response = Maremma.get(url, host: true)

      return [] if response.status != 200

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
end
