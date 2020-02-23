# frozen_string_literal: true

class QueryType < BaseObject
  extend_type

  field :providers, ProviderConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def providers(query: nil, year: nil, first: nil)
    Provider.query(query, year: year, page: { number: 1, size: first }).results.to_a
  end

  field :provider, ProviderType, null: false do
    argument :id, ID, required: true
  end

  def provider(id:)
    ElasticsearchLoader.for(Provider).load(id)
  end

  field :clients, ClientConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :year, String, required: false
    argument :software, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def clients(query: nil, year: nil, software: nil, first: nil)
    Client.query(query, year: year, software: software, page: { number: 1, size: first }).results.to_a
  end

  field :client, ClientType, null: false do
    argument :id, ID, required: true
  end

  def client(id:)
    ElasticsearchLoader.for(Client).load(id)
  end

  field :prefixes, [PrefixType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def prefixes(query: nil, first: nil)
    if query.present?
      collection = Prefix.query(query)
    else
      collection = Prefix.all
    end

    collection.page(1).per(first)
  end

  field :prefix, PrefixType, null: false do
    argument :id, ID, required: true
  end

  def prefix(id:)
    #ActiveRecordLoader.for(Prefix).load(id)
    Prefix.where(prefix: id).first
  end

  field :funders, FunderConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def funders(query: nil, first: nil)
    Funder.query(query, limit: first).fetch(:data, [])
  end

  field :funder, FunderType, null: false do
    argument :id, ID, required: true
  end

  def funder(id:)
    result = Funder.find_by_id(id).fetch(:data, []).first
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  field :data_catalog, DataCatalogType, null: false do
    argument :id, ID, required: true
  end

  def data_catalog(id:)
    result = DataCatalog.find_by_id(id).fetch(:data, []).first
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  field :data_catalogs, DataCatalogConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def data_catalogs(query: nil, first: nil)
    DataCatalog.query(query, limit: first).fetch(:data, [])
  end

  field :organizations, OrganizationConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def organizations(query: nil, first: nil)
    Organization.query(query, limit: first).fetch(:data, [])
  end

  field :organization, OrganizationType, null: false do
    argument :id, ID, required: true
  end

  def organization(id:)
    result = Organization.find_by_id(id).fetch(:data, []).first
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  field :person, PersonType, null: true do
    argument :id, ID, required: true
  end

  def person(id:)
    result = Person.find_by_id(id).fetch(:data, []).first
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  field :people, PersonConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def people(query: nil, first: nil)
    Person.query(query, limit: first).fetch(:data, [])
  end

  field :creative_works, CreativeWorkConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def creative_works(query: nil, ids: nil, client_id: nil, provider_id: nil, first: nil)
    if ids.present?
      dois = ids.split(",").map { |i| doi_from_url(i) }
      Doi.find_by_ids(dois, page: { number: 1, size: first }).results.to_a
    else
      Doi.query(query, client_id: client_id, provider_id: provider_id, state: "findable", page: { number: 1, size: first }).results.to_a
    end
  end

  field :creative_work, CreativeWorkType, null: false do
    argument :id, ID, required: true
  end

  def creative_work(id:)
    set_doi(id)
  end

  field :datasets, DatasetConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(query: nil, client_id: nil, provider_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, client_id: client_id, provider_id: provider_id, resource_type_id: "Dataset", state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
  end

  field :dataset, DatasetType, null: false do
    argument :id, ID, required: true
  end

  def dataset(id:)
    set_doi(id)
  end

  field :publications, PublicationConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def publications(query: nil, client_id: nil, provider_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, client_id: client_id, provider_id: provider_id, has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, resource_type_id: "Text", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :publication, PublicationType, null: false do
    argument :id, ID, required: true
  end

  def publication(id:)
    set_doi(id)
  end

  field :audiovisuals, [AudiovisualType], null: false do
    argument :query, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def audiovisuals(query: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, resource_type_id: "Audiovisual", state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
  end

  field :audiovisual, AudiovisualType, null: false do
    argument :id, ID, required: true
  end

  def audiovisual(id:)
    set_doi(id)
  end

  field :collections, [CollectionType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def collections(query: nil, first: nil)
    Doi.query(query, resource_type_id: "Collection", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :collection, CollectionType, null: false do
    argument :id, ID, required: true
  end

  def collection(id:)
    set_doi(id)
  end

  field :data_papers, [DataPaperType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def data_papers(query: nil, first: nil)
    Doi.query(query, resource_type_id: "DataPaper", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :data_paper, DataPaperType, null: false do
    argument :id, ID, required: true
  end

  def data_paper(id:)
    set_doi(id)
  end

  field :events, [EventType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def events(query: nil, first: nil)
    Doi.query(query, resource_type_id: "Event", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :event, EventType, null: false do
    argument :id, ID, required: true
  end

  def event(id:)
    set_doi(id)
  end

  field :images, [ImageType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def images(query: nil, first: nil)
    Doi.query(query, resource_type_id: "Image", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :image, ImageType, null: false do
    argument :id, ID, required: true
  end

  def image(id:)
    set_doi(id)
  end

  field :interactive_resources, [InteractiveResourceType], null: false do
    argument :query, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def interactive_resources(query: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, resource_type_id: "InteractiveResource", state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
  end

  field :interactive_resource, InteractiveResourceType, null: false do
    argument :id, ID, required: true
  end

  def interactive_resource(id:)
    set_doi(id)
  end

  field :models, [ModelType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def models(query: nil, first: nil)
    Doi.query(query, resource_type_id: "Model", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :model, ModelType, null: false do
    argument :id, ID, required: true
  end

  def model(id:)
    set_doi(id)
  end

  field :physical_objects, [PhysicalObjectType], null: false do
    argument :query, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def physical_objects(query: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, resource_type_id: "PhysicalObject", state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
  end

  field :physical_object, PhysicalObjectType, null: false do
    argument :id, ID, required: true
  end

  def physical_object(id:)
    set_doi(id)
  end

  field :services, ServiceConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def services(query: nil, first: nil)
    Doi.query(query, resource_type_id: "Service", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :service, ServiceType, null: false do
    argument :id, ID, required: true
  end

  def service(id:)
    set_doi(id)
  end

  field :software_source_codes, SoftwareConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def software_source_codes(query: nil, client_id: nil, provider_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, client_id: client_id, provider_id: provider_id, has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, resource_type_id: "Software", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :software_source_code, SoftwareType, null: false do
    argument :id, ID, required: true
  end

  def software_source_code(id:)
    set_doi(id)
  end

  field :sounds, [SoundType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def sounds(query: nil, first: nil)
    Doi.query(query, resource_type_id: "Sound", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :sound, SoundType, null: false do
    argument :id, ID, required: true
  end

  def sound(id:)
    set_doi(id)
  end

  field :workflows, [WorkflowType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def workflows(query: nil, first: nil)
    Doi.query(query, resource_type_id: "Workflow", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :workflow, WorkflowType, null: false do
    argument :id, ID, required: true
  end

  def workflow(id:)
    set_doi(id)
  end

  field :others, [OtherType], null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def others(query: nil, first: nil)
    Doi.query(query, resource_type_id: "Other", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  field :other, OtherType, null: false do
    argument :id, ID, required: true
  end

  def other(id:)
    set_doi(id)
  end

  field :usage_reports, UsageReportConnectionWithMetaType, null: false, connection: true, max_page_size: 1000 do
    argument :first, Int, required: false, default_value: 25
  end

  def usage_reports(first: nil)
    UsageReport.query(nil, page: { number: 1, size: first }).fetch(:data, [])
  end

  field :usage_report, UsageReportType, null: false do
    argument :id, ID, required: true
  end

  def usage_report(id:)
    result = UsageReport.find_by_id(id).fetch(:data, []).first
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  def set_doi(id)
    doi = doi_from_url(id)
    fail ActiveRecord::RecordNotFound if doi.nil?

    result = ElasticsearchLoader.for(Doi).load(doi)
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end

  def orcid_from_url(url)
    Array(/\A(http|https):\/\/orcid\.org\/(.+)/.match(url)).last
  end
end
