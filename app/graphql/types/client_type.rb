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
  
  field :prefixes, PrefixConnectionWithMetaType, null: true, description: "Prefixes managed by the client", connection: true do
    argument :query, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :datasets, DatasetConnectionWithMetaType, null: true, connection: true, description: "Datasets managed by the client" do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionWithMetaType, null: true, connection: true, description: "Publications managed by the client" do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionWithMetaType, null: true, connection: true, description: "Software managed by the client" do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionWithMetaType, null: true, connection: true, description: "Works managed by the client" do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :prefixes, ClientPrefixConnectionWithMetaType, null: true, description: "Prefixes managed by the client", connection: true do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Client"
  end

  def datasets(**args)
    Doi.query(args[:query], user_id: args[:user_id].present? ? orcid_from_url(args[:user_id]) : nil, client_id: object.uid, resource_type_id: "Dataset", page: { number: 1, size: args[:first] }).results.to_a
  end

  def publications(**args)
    Doi.query(args[:query], user_id: args[:user_id].present? ? orcid_from_url(args[:user_id]) : nil, client_id: object.uid, resource_type_id: "Text", page: { number: 1, size: args[:first] }).results.to_a
  end

  def softwares(**args)
    Doi.query(args[:query], user_id: args[:user_id].present? ? orcid_from_url(args[:user_id]) : nil, client_id: object.uid, resource_type_id: "Software", page: { number: 1, size: args[:first] }).results.to_a
  end

  def works(**args)
    Doi.query(args[:query], user_id: args[:user_id].present? ? orcid_from_url(args[:user_id]) : nil, client_id: object.uid, page: { number: 1, size: args[:first] }).results.to_a
  end

  def prefixes(**args)
    ClientPrefix.query(args[:query], client_id: object.uid, state: args[:state], year: args[:year], page: { number: 1, size: args[:first] }).results.to_a
  end

  def view_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.views.buckets) : []
  end

  def download_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.downloads.buckets) : []
  end

  def citation_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.citations.buckets) : []
  end

  def response
    @response ||= Doi.query(nil, client_id: object.uid, state: "findable", page: { number: 1, size: 0 })
  end
end
