# frozen_string_literal: true

class Types::RepositoryType < Types::BaseObject
  description "Information about repositories"

  field :id, ID, null: false, hash_key: "uid", description: "Unique identifier for each repository"
  field :type, String, null: false, description: "The type of the item."
  field :re3data, ID, null: true, description: "The re3data identifier for the repository"
  field :name, String, null: false, description: "Repository name"
  field :alternate_name, String, null: true, description: "Repository alternate name"
  field :description, String, null: true, description: "Description of the repository"
  field :url, Types::Url, null: true, description: "The homepage of the repository"
  field :software, String, null: true, description: "The name of the software that is used to run the repository"
  field :client_type, String, null: true, description: "The client type (repository or periodical)"
  field :repository_type, [String], null: true, description: "The repository type(s)"
  field :certificate, [String], null: true, description: "The certificate(s) for the repository"
  field :language, [String], null: true, description: "The langauge of the repository"
  field :issn, Types::IssnType, null: true, description: "The ISSN"
    
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice."
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice."
  field :citation_count, Integer, null: true, description: "The number of citations."

  field :datasets, Types::DatasetConnectionType, null: true, connection: true, description: "Datasets managed by the repository" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :member_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, Types::PublicationConnectionType, null: true, connection: true, description: "Publications managed by the repository" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :member_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, Types::SoftwareConnectionType, null: true, connection: true, description: "Software managed by the repository" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :member_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, Types::WorkConnectionType, null: true, connection: true, description: "Works managed by the repository" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :member_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :prefixes, Types::RepositoryPrefixConnectionType, null: true, description: "Prefixes managed by the repository", connection: true do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Repository"
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    r = response(args)

    r.results.to_a
  end

  def publications(**args)
    args[:resource_type_id] = "Text"
    r = response(args)

    r.results.to_a
  end

  def softwares(**args)
    args[:resource_type_id] = "Software"
    r = response(args)

    r.results.to_a
  end

  def works(**args)
    r = response(args)

    r.results.to_a
  end

  def prefixes(**args)
    ClientPrefix.query(args[:query], client_id: object.uid, state: args[:state], year: args[:year], page: { number: 1, size: args[:first] }).results.to_a
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
    Doi.query(args[:query], funder_id: args[:funder_id], user_id: args[:user_id], client_id: object.uid, provider_id: args[:member_id], affiliation_id: args[:affiliation_id], resource_type_id: args[:resource_type_id], has_person: args[:has_person], has_organization: args[:has_organization], has_funder: args[:has_funder], has_citations: args[:has_citations], has_parts: args[:has_parts], has_versions: args[:has_versions], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] })
  end
end
