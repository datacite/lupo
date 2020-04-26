# frozen_string_literal: true

class Types::BaseObject < GraphQL::Schema::Object
  include ApolloFederation::Object

  field_class Types::BaseField

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end

  def orcid_from_url(url)
    if /\A(?:(http|https):\/\/(orcid.org)\/)(.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end

  def facet_by_year(arr)
    arr.map do |hsh|
      { "id" => hsh["key_as_string"][0..3],
        "title" => hsh["key_as_string"][0..3],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_resource_type(arr)
    arr.map do |hsh|
      { "id" => hsh["key"].underscore.dasherize,
        "title" => hsh["key"],
        "count" => hsh["doc_count"] }
    end
  end

  def aggregate_count(arr)
    arr.reduce(0) do |sum, hsh|
      sum + hsh.dig("metric_count", "value").to_i
      sum
    end
  end
end
