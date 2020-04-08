# frozen_string_literal: true

class PersonType < BaseObject
  description "A person."

  field :id, ID, null: true, description: "The ORCID ID of the person."
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: true, description: "The name of the person."
  field :given_name, String, null: true, description: "Given name. In the U.S., the first name of a Person."
  field :family_name, String, null: true, description: "Family name. In the U.S., the last name of an Person."
  field :affiliation, [AffiliationType], null: true, description: "Affiliations(s) of the person."
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice."
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice."
  field :citation_count, Integer, null: true, description: "The number of citations."

  field :datasets, DatasetConnectionType, null: true, connection: true, max_page_size: 1000, description: "Authored datasets" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionType, null: true, connection: true, max_page_size: 1000, description: "Authored publications"  do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionType, null: true, connection: true, max_page_size: 1000, description: "Authored software"  do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionType, null: true, connection: true, max_page_size: 1000, description: "Authored works" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
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
    Doi.query(args[:query], user_id: object[:id], client_id: args[:client_id], provider_id: args[:provider_id], affiliation_id: args[:affiliation_id], resource_type_id: args[:resource_type_id], has_funder: args[:has_funder], has_affiliation: args[:has_affiliation], has_citations: args[:has_citations], has_parts: args[:has_parts], has_versions: args[:has_versions], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] })
  end
end
