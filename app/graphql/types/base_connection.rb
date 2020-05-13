# frozen_string_literal: true

class BaseConnection < GraphQL::Types::Relay::BaseConnection
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

  def prepare_args(args)
    args[:user_id] ||= object.parent.try(:type) == "Person" ? object.parent.orcid : nil
    args[:repository_id] ||= object.parent.try(:client_type).present? ? object.parent.symbol.downcase : nil
    args[:member_id] ||= object.parent.try(:region).present? ? object.parent.symbol.downcase : nil
    args[:affiliation_id] ||= object.parent.try(:type) == "Organization" ? object.parent[:id] : nil
    args[:funder_id] ||= object.parent.try(:type) == "Funder" ? object.parent[:id] : nil
    args[:re3data_id] ||= object.parent.try(:type) == "DataCatalog" ? object.parent[:id] : nil
    args.compact
  end

  def facet_by_year(arr)
    arr.map do |hsh|
      { "id" => hsh["key_as_string"][0..3],
        "title" => hsh["key_as_string"][0..3],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_key(arr)
    arr.map do |hsh|
      { "id" => hsh["key"],
        "title" => hsh["key"].titleize,
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

  def facet_by_software(arr)
    arr.map do |hsh|
      { "id" => hsh["key"].downcase,
        "title" => hsh["key"],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_combined_key(arr)
    arr.map do |hsh|
      id, title = hsh["key"].split(":", 2)

      { "id" => id,
        "title" => title,
        "count" => hsh["doc_count"] }
    end
  end
end
