# frozen_string_literal: true

class FunderType < BaseObject
  description "Information about funders"

  field :id, ID, null: false, description: "Crossref Funder ID"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, description: "The name of the funder."
  field :alternate_name, [String], null: true, description: "An alias for the funder."
  field :address, AddressType, null: true, description: "Physical address of the funder."
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice."
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice."
  field :citation_count, Integer, null: true, description: "The number of citations."

  field :datasets, DatasetConnectionWithMetaType, null: true, description: "Funded datasets", connection: true do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionWithMetaType, null: true, description: "Funded publications", connection: true do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionWithMetaType, null: true, description: "Funded software", connection: true do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionWithMetaType, null: true, description: "Funded works", connection: true do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def address
    { "type" => "postalAddress",
      "country" => object.country.to_h.fetch("name", nil) }
  end

  def publications(**args)
    args[:resource_type_id] = "Text"
    r = response(**args)

    r.results.to_a
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    r = response(**args)

    r.results.to_a
  end

  def softwares(**args)
    args[:resource_type_id] = "Software"
    r = response(**args)

    r.results.to_a
  end

  def works(**args)
    r = response(**args)

    r.results.to_a
  end

  def view_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.views.buckets) : 0
  end

  def download_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.downloads.buckets) : 0
  end

  def citation_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.citations.buckets) : 0
  end

  def response(**args)
    Doi.query(args[:query], funder_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], affiliation_id: args[:affiliation_id], resource_type_id: args[:resource_type_id], has_person: args[:has_person], has_organization: args[:has_organization], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] })
  end
end
