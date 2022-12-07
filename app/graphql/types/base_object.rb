# frozen_string_literal: true

class BaseObject < GraphQL::Schema::Object
  include ApolloFederation::Object

  include Identifiable
  include Facetable
  include Modelable

  field_class BaseField


  def orcid_from_url(url)
    if %r{\A(?:(http|https)://(orcid.org)/)(.+)\z}.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(%r{^/}, "").upcase
    end
  end

  def ror_id_from_url(url)
    Array(%r{\A(http|https)://(ror\.org/0\w{6}\d{2})\z}.match(url)).last
  end

  def facet_by_year(arr)
    arr.map do |hsh|
      {
        "id" => hsh["key_as_string"][0..3],
        "title" => hsh["key_as_string"][0..3],
        "count" => hsh["doc_count"],
      }
    end
  end


  def aggregate_count(arr)
    arr.reduce(0) do |sum, hsh|
      sum + hsh.dig("metric_count", "value").to_i
      sum
    end
  end
end
