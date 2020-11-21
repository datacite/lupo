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
      return {} if wikidata_id.blank?

      url = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wikidata_id}&languages=en&props=labels|descriptions|claims&format=json"

      response = Maremma.get(url, host: true)

      return {} if response.status != 200

      response.body
    end

    def parse_wikidata_message(id: nil, message: nil)
      name = message.dig("entities", id, "labels", "en", "value")

      claims = message.dig("entities", id, "claims") || {}
      twitter = claims.dig("P2002", 0, "mainsnak", "datavalue", "value")
      inception = claims.dig("P571", 0, "mainsnak", "datavalue", "value", "time")
      # extract year, e.g. +1961-00-00 to 1961
      inception_year = inception[1..4] if inception.present?
      geolocation = claims.dig("P625", 0, "mainsnak", "datavalue", "value") ||
        claims.dig("P625", 0, "datavalue", "value") ||
        claims.dig("P159", 0, "qualifiers", "P625", 0, "datavalue", "value") || {}
      ringgold = claims.dig("P3500", 0, "mainsnak", "datavalue", "value")

      Hashie::Mash.new(
        id: id,
        type: "Organization",
        name: name,
        twitter: twitter,
        inception_year: inception_year,
        geolocation: geolocation.extract!("longitude", "latitude"),
        ringgold: ringgold,
      )
    end

    def wikidata_query(employment)
      return [] if employment.blank?

      ringgold_filter = Array.wrap(employment).reduce([]) do |sum, f|
        sum << f["ringgold"] if f["ringgold"]

        sum
      end.join('", "')

      grid_filter = Array.wrap(employment).reduce([]) do |sum, f|
        sum << f["grid"] if f["grid"]

        sum
      end.join('", "')

      user_agent = "Mozilla/5.0 (compatible; Maremma/4.7.1; mailto:info@datacite.org)"
      endpoint = "https://query.wikidata.org/sparql"
      sparql = <<"SPARQL".chop
      PREFIX wikibase: <http://wikiba.se/ontology#>
      PREFIX wd: <http://www.wikidata.org/entity/>
      PREFIX wdt: <http://www.wikidata.org/prop/direct/>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX p: <http://www.wikidata.org/prop/>
      PREFIX v: <http://www.wikidata.org/prop/statement/>

      SELECT ?item ?itemLabel ?ror ?grid ?ringgold WHERE {
        ?item wdt:P6782 ?ror.
        OPTIONAL { ?item wdt:P2427 ?grid. }
        OPTIONAL { ?item wdt:P3500 ?ringgold. }

        FILTER(?ringgold in ("#{ringgold_filter}") || ?grid in ("#{grid_filter}")).
           SERVICE wikibase:label {
             bd:serviceParam wikibase:language "[AUTO_LANGUAGE]" .
           }
         }
SPARQL

      client = SPARQL::Client.new(endpoint,
                                  method: :get,
                                  headers: { "User-Agent" => user_agent })
      response = client.query(sparql)

      ringgold_to_ror = Array.wrap(response).reduce({}) do |sum, r|
        sum[r[:ringgold].to_s] = "https://ror.org/" + r[:ror] if r[:ror] && r[:ringgold]
        sum
      end

      grid_to_ror = Array.wrap(response).reduce({}) do |sum, r|
        sum[r[:grid].to_s] = "https://ror.org/" + r[:ror] if r[:ror] && r[:grid]
        sum
      end

      Array.wrap(employment).reduce([]) do |sum, e|
        if ringgold_to_ror[e["ringgold"]]
          e["organization_id"] = ringgold_to_ror[e["ringgold"]]
        elsif grid_to_ror[e["grid"]]
          e["organization_id"] = grid_to_ror[e["grid"]]
        end

        e.except!("ringgold", "grid")
        sum << e
        sum
      end
    end
  end
end
