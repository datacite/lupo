# frozen_string_literal: true

class ClientType < BaseObject
  description "Information about clients"

  field :id, ID, null: false, hash_key: "uid", description: "Unique identifier for each client"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, description: "Client name"
  field :alternate_name, String, null: true, description: "Client alternate name"
  field :re3data, String, null: true, description: "The re3data identifier for the client"
  field :description, String, null: true, description: "Description of the client"
  field :url, String, null: true, description: "The homepage of the client"
  field :system_email, String, null: true, description: "Client system email"
  field :software, String, null: true, description: "The name of the software that is used to run the repository"
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice."
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice."
  field :citation_count, Integer, null: true, description: "The number of citations."
  
  field :prefixes, PrefixConnectionType, null: true, description: "Prefixes managed by the client", connection: true do
    argument :query, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :datasets, DatasetConnectionType, null: true, connection: true, description: "Datasets managed by the client" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :provider_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionType, null: true, connection: true, description: "Publications managed by the client" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :provider_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionType, null: true, connection: true, description: "Software managed by the client" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :provider_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionType, null: true, connection: true, description: "Works managed by the client" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :provider_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :prefixes, ClientPrefixConnectionType, null: true, description: "Prefixes managed by the client", connection: true do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Client"
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    r = response(**args)

    r.results.to_a
  end

  def publications(**args)
    args[:resource_type_id] = "Text"
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

  def prefixes(**args)
    ClientPrefix.query(args[:query], client_id: object.uid, state: args[:state], year: args[:year], page: { number: 1, size: args[:first] }).results.to_a
  end

  def view_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.views.buckets) : []
  end

  def download_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.downloads.buckets) : []
  end

  def citation_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.citations.buckets) : []
  end

  def response(**args)
    Doi.query(args[:query], funder_id: args[:funder_id], user_id: args[:user_id], client_id: object.uid, provider_id: args[:provider_id], affiliation_id: args[:affiliation_id], resource_type_id: args[:resource_type_id], has_person: args[:has_person], has_organization: args[:has_organization], has_funder: args[:has_funder], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] })
  end
end
