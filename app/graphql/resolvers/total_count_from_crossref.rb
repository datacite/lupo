# frozen_string_literal: true

class TotalCountFromCrossref < Base
  type Int, null: false

  def resolve
    # Use Crossref API to get current number of Crossref works
    url = "https://api.crossref.org/works?rows=0&mailto=info@datacite.org"
    response = Maremma.get(url)
    return nil if response.status != 200

    response.body.dig("data", "message", "total-results")
  end
end
