# frozen_string_literal: true

class ContentUrl < Resolvers::Base
  type Url, null: false

  def resolve
    # Use Unpaywall API if DOI is from Crossref
    # This will be a future feature in the DataCite metadata schema
    return nil if object.agency != "crossref"

    url = "https://api.unpaywall.org/v2/#{object.doi}?email=info@datacite.org"
    response = Maremma.get(url)
    return nil if response.status != 200

    response.body.dig("data", "best_oa_location", "url")
  end
end
