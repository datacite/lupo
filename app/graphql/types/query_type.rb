# frozen_string_literal: true

class QueryType < BaseObject
  extend_type

  field :providers, ProviderConnectionType, null: false, connection: true, max_page_size: 1000 do
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
    Provider.unscoped.where("allocator.role_name IN ('ROLE_FOR_PROFIT_PROVIDER', 'ROLE_CONTRACTUAL_PROVIDER', 'ROLE_CONSORTIUM' , 'ROLE_CONSORTIUM_ORGANIZATION', 'ROLE_ALLOCATOR', 'ROLE_ADMIN', 'ROLE_MEMBER', 'ROLE_REGISTRATION_AGENCY')").where(deleted_at: nil).where(symbol: id).first
  end

  field :clients, ClientConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :year, String, required: false
    argument :software, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def clients(**args)
    Client.query(args[:query], year: args[:year], software: args[:software], page: { number: 1, size: args[:first] }).results.to_a
  end

  field :client, ClientType, null: false do
    argument :id, ID, required: true
  end

  def client(id:)
    Client.where(symbol: id).where(deleted_at: nil).first
  end

  field :prefixes, PrefixConnectionType, null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def prefixes(**args)
    Prefix.query(args[:query], page: { number: 1, size: args[:first] }).results.to_a
  end

  field :prefix, PrefixType, null: false do
    argument :id, ID, required: true
  end

  def prefix(id:)
    Prefix.where(prefix: id).first
  end

  field :funders, FunderConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def funders(**args)
    Funder.query(args[:query], limit: args[:first]).fetch(:data, [])
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

  field :data_catalogs, DataCatalogConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def data_catalogs(**args)
    DataCatalog.query(args[:query], limit: args[:first]).fetch(:data, [])
  end

  field :organizations, OrganizationConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
  end

  def organizations(**args)
    Organization.query(args[:query]).fetch(:data, [])
  end

  field :organization, OrganizationType, null: false do
    argument :id, ID, required: true
  end

  def organization(id:)
    result = Organization.find_by_id(id).fetch(:data, []).first
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  field :person, PersonType, null: false do
    argument :id, ID, required: true
  end

  def person(id:)
    result = Person.find_by_id(id).fetch(:data, []).first
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  field :people, PersonConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def people(**args)
    Person.query(args[:query], limit: args[:first]).fetch(:data, [])
  end

  field :works, WorkConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def works(**args)
    response(**args)
  end

  field :work, WorkType, null: false do
    argument :id, ID, required: true
  end

  def work(id:)
    set_doi(id)
  end

  field :datasets, DatasetConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    response(**args)
  end

  field :dataset, DatasetType, null: false do
    argument :id, ID, required: true
  end

  def dataset(id:)
    set_doi(id)
  end

  field :publications, PublicationConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
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
    response(**args)
  end

  field :publication, PublicationType, null: false do
    argument :id, ID, required: true
  end

  def publication(id:)
    set_doi(id)
  end

  field :audiovisuals, AudiovisualConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def audiovisuals(**args)
    args[:resource_type_id] = "Audiovisual"
    response(**args)
  end

  field :audiovisual, AudiovisualType, null: false do
    argument :id, ID, required: true
  end

  def audiovisual(id:)
    set_doi(id)
  end

  field :collections, CollectionConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def collections(**args)
    args[:resource_type_id] = "Collection"
    response(**args)
  end

  field :collection, CollectionType, null: false do
    argument :id, ID, required: true
  end

  def collection(id:)
    set_doi(id)
  end

  field :data_papers, DataPaperConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def data_papers(**args)
    args[:resource_type_id] = "DataPaper"
    response(**args)
  end

  field :data_paper, DataPaperType, null: false do
    argument :id, ID, required: true
  end

  def data_paper(id:)
    set_doi(id)
  end

  field :events, EventConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def events(**args)
    args[:resource_type_id] = "Event"
    response(**args)
  end

  field :event, EventType, null: false do
    argument :id, ID, required: true
  end

  def event(id:)
    set_doi(id)
  end

  field :images, ImageConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def images(**args)
    args[:resource_type_id] = "Image"
    response(**args)
  end

  field :image, ImageType, null: false do
    argument :id, ID, required: true
  end

  def image(id:)
    set_doi(id)
  end

  field :interactive_resources, InteractiveResourceConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def interactive_resources(**args)
    args[:resource_type_id] = "InteractiveResource"
    response(**args)
  end

  field :interactive_resource, InteractiveResourceType, null: false do
    argument :id, ID, required: true
  end

  def interactive_resource(id:)
    set_doi(id)
  end

  field :models, ModelConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def models(**args)
    args[:resource_type_id] = "Model"
    response(**args)
  end

  field :model, ModelType, null: false do
    argument :id, ID, required: true
  end

  def model(id:)
    set_doi(id)
  end

  field :physical_objects, PhysicalObjectConnectionType, null: false do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def physical_objects(**args)
    args[:resource_type_id] = "PhysicalObject"
    response(**args)
  end

  field :physical_object, PhysicalObjectType, null: false do
    argument :id, ID, required: true
  end

  def physical_object(id:)
    set_doi(id)
  end

  field :services, ServiceConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def services(**args)
    args[:resource_type_id] = "Service"
    response(**args)
  end

  field :service, ServiceType, null: false do
    argument :id, ID, required: true
  end

  def service(id:)
    set_doi(id)
  end

  field :softwares, SoftwareConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def softwares(**args)
    args[:resource_type_id] = "Software"
    response(**args)
  end

  field :software, SoftwareType, null: false do
    argument :id, ID, required: true
  end

  def software(id:)
    set_doi(id)
  end

  field :sounds, SoundConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def sounds(**args)
    args[:resource_type_id] = "Sound"
    response(**args)
  end

  field :sound, SoundType, null: false do
    argument :id, ID, required: true
  end

  def sound(id:)
    set_doi(id)
  end

  field :workflows, WorkflowConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def workflows(**args)
    args[:resource_type_id] = "Workflow"
    response(**args)
  end

  field :workflow, WorkflowType, null: false do
    argument :id, ID, required: true
  end

  def workflow(id:)
    set_doi(id)
  end

  field :theses, ThesisConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def theses(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "thesis"
    response(**args)
  end

  field :thesis, PublicationType, null: false do
    argument :id, ID, required: true
  end

  def thesis(id:)
    set_doi(id)
  end

  field :instruments, InstrumentConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def instruments(**args)
    args[:resource_type_id] = "Other"
    args[:resource_type] = "Instrument"

    response(**args)
  end

  field :instrument, OtherType, null: false do
    argument :id, ID, required: true
  end

  def instrument(id:)
    set_doi(id)
  end

  field :others, OtherConnectionType, null: false, connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def others(**args)
    args[:resource_type_id] = "Other"
    response(**args)
  end

  field :other, OtherType, null: false do
    argument :id, ID, required: true
  end

  def other(id:)
    set_doi(id)
  end

  field :usage_reports, UsageReportConnectionType, null: false, connection: true, max_page_size: 1000 do
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

  def response(**args)
    @response ||= Doi.query(args[:query], ids: args[:ids], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], resource_type_id: args[:resource_type_id], resource_type: args[:resource_type], has_person: args[:has_person], has_funder: args[:has_funder], has_organization: args[:has_organization], has_citations: args[:has_citations], has_parts: args[:has_parts], has_versions: args[:has_versions], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] }).results.to_a
  end

  def set_doi(id)
    doi = doi_from_url(id)
    fail ActiveRecord::RecordNotFound if doi.nil?

    result = ElasticsearchLoader.for(Doi).load(doi)
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end
end
