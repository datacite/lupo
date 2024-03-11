# frozen_string_literal: true

class QueryType < BaseObject
  extend_type

  field :members, MemberConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def members(**args)
    response = Provider.query(args[:query], year: args[:year], page: { cursor: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil, size: args[:first] })
    ElasticsearchModelResponseConnection.new(response, context: context, first: args[:first], after: args[:after])
  end

  field :member, MemberType, null: false do
    argument :id, ID, required: true
  end

  def member(id:)
    Provider.unscoped.where("allocator.role_name IN ('ROLE_FOR_PROFIT_PROVIDER', 'ROLE_CONTRACTUAL_PROVIDER', 'ROLE_CONSORTIUM' , 'ROLE_CONSORTIUM_ORGANIZATION', 'ROLE_ALLOCATOR', 'ROLE_ADMIN', 'ROLE_MEMBER', 'ROLE_DEV')").where(deleted_at: nil).where(symbol: id).first
  end

  field :me, MeType, null: true

  def me
    context[:current_user]
  end

  field :repositories, RepositoryConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :software, String, required: false
    argument :certificate, String, required: false
    argument :repositoryType, String, required: false
    argument :subject, String, required: false
    argument :subjectId, String, required: false
    argument :isOpen, String, required: false
    argument :isDisciplinary, String, required: false
    argument :isCertified, String, required: false
    argument :hasPid, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def repositories(**args)
    response = ReferenceRepository.query(
      args[:query],
      software: args[:software],
      certificate: args[:certificate],
      subject: args[:subject],
      subject_id: args[:subject_id],
      repository_type: args[:repository_type],
      is_open: args[:is_open],
      is_certified: args[:is_certified],
      is_disciplinary: args[:is_disciplinary],
      has_pid: args[:has_pid],
      page: {
        cursor: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil,
        size: args[:first]
      }
    )
    ElasticsearchModelResponseConnection.new(
      response,
      context: context,
      first: args[:first],
      after: args[:after]
    )
  end

  field :repository, RepositoryType, null: false do
    argument :id, ID, required: true
  end
  def repository(id:)
    ReferenceRepository.find_by_id(id).first
  end


  field :prefixes, PrefixConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def prefixes(**args)
    response = Prefix.query(args[:query], page: { cursor: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil, size: args[:first] })
    ElasticsearchModelResponseConnection.new(response, context: context, first: args[:first], after: args[:after])
  end

  field :prefix, PrefixType, null: false do
    argument :id, ID, required: true
  end

  def prefix(id:)
    Prefix.where(prefix: id).first
  end

  field :funders, FunderConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def funders(**args)
    response = Funder.query(args[:query], limit: args[:first], offset: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil)
    HashConnection.new(response, context: context, first: args[:first], after: args[:after])
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

  field :data_catalogs, DataCatalogConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :subject, String, required: false
    argument :open, String, required: false
    argument :certified, String, required: false
    argument :pid, String, required: false
    argument :software, String, required: false
    argument :disciplinary, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def data_catalogs(**args)
    response = DataCatalog.query(
      args[:query],
        subject: args[:subject],
        open: args[:open],
        certified: args[:certified],
        pid: args[:pid],
        software: args[:software],
        disciplinary: args[:disciplinary],
        limit: args[:first],
        offset: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil
    )
    HashConnection.new(response, context: context, first: args[:first], after: args[:after])
  end

  field :organizations, OrganizationConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :after, String, required: false
    argument :types, String, required: false
    argument :country, String, required: false
  end

  def organizations(**args)
    response = Organization.query(args[:query], types: args[:types], country: args[:country], offset: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil)
    HashConnection.new(response, context: context, after: args[:after])
  end

  field :organization, OrganizationType, null: false do
    argument :id, ID, required: false
    argument :grid_id, ID, required: false
    argument :crossref_funder_id, ID, required: false
  end

  def organization(id: nil, grid_id: nil, crossref_funder_id: nil)
    result = nil

    if id.present?
      result = Organization.find_by_id(id).fetch(:data, []).first
    elsif grid_id.present?
      result = Organization.find_by_grid_id(grid_id).fetch(:data, []).first
    elsif crossref_funder_id.present?
      result = Organization.find_by_crossref_funder_id(crossref_funder_id).fetch(:data, []).first
    end

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

  field :people, PersonConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def people(**args)
    query = args[:query]&.gsub(/^https?:\/\//, "")
    response = Person.query(query, limit: args[:first], offset: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil)
    HashConnection.new(response, context: context, first: args[:first], after: args[:after])
  end

  field :actors, ActorConnectionType, null: false, connection: false do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def actors(**args)
    orgs = Organization.query(args[:query], offset: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil)
    funders = Funder.query(args[:query], limit: args[:first], offset: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil)
    people = Person.query(args[:query], limit: args[:first], offset: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil)

    response = {
      data: Array.wrap(orgs[:data]) + Array.wrap(funders[:data]) + Array.wrap(people[:data]),
      meta: { "total" => (orgs.dig(:meta, "total").to_i + funders.dig(:meta, "total").to_i + people.dig(:meta, "total").to_i) },
    }
    HashConnection.new(response, context: context, first: args[:first], after: args[:after])
  end

  field :actor, ActorItem, null: false do
    argument :id, ID, required: true
  end

  def actor(id:)
    result = if orcid_from_url(id)
      Person.find_by_id(id).fetch(:data, []).first
    elsif ror_id_from_url(id)
      Organization.find_by_id(id).fetch(:data, []).first
    elsif doi_from_url(id).to_s.starts_with?("10.13039")
      Funder.find_by_id(id).fetch(:data, []).first
    end

    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  field :works, WorkConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def works(**args)
    ElasticsearchModelResponseConnection.new(
      response(**args),
      context: context,
      first: args[:first],
      after: args[:after])
  end

  field :work, WorkType, null: false do
    argument :id, ID, required: true
  end

  def work(id:)
    set_doi(id)
  end

  field :datasets, DatasetConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :dataset, DatasetType, null: false do
    argument :id, ID, required: true
  end

  def dataset(id:)
    set_doi(id)
  end

  field :publications, PublicationConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def publications(**args)
    args[:resource_type_id] = "Text"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :publication, PublicationType, null: false do
    argument :id, ID, required: true
  end

  def publication(id:)
    set_doi(id)
  end

  field :audiovisuals, AudiovisualConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def audiovisuals(**args)
    args[:resource_type_id] = "Audiovisual"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :audiovisual, AudiovisualType, null: false do
    argument :id, ID, required: true
  end

  def audiovisual(id:)
    set_doi(id)
  end

  field :collections, CollectionConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def collections(**args)
    args[:resource_type_id] = "Collection"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :collection, CollectionType, null: false do
    argument :id, ID, required: true
  end

  def collection(id:)
    set_doi(id)
  end

  field :data_papers, DataPaperConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def data_papers(**args)
    args[:resource_type_id] = "DataPaper"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :data_paper, DataPaperType, null: false do
    argument :id, ID, required: true
  end

  def data_paper(id:)
    set_doi(id)
  end

  # NOTE: This "Event" is a type of work
  field :events, EventConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def events(**args)
    args[:resource_type_id] = "Event"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :event, EventType, null: false do
    argument :id, ID, required: true
  end

  def event(id:)
    set_doi(id)
  end

  field :images, ImageConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def images(**args)
    args[:resource_type_id] = "Image"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :image, ImageType, null: false do
    argument :id, ID, required: true
  end

  def image(id:)
    set_doi(id)
  end

  field :interactive_resources, InteractiveResourceConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def interactive_resources(**args)
    args[:resource_type_id] = "InteractiveResource"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :interactive_resource, InteractiveResourceType, null: false do
    argument :id, ID, required: true
  end

  def interactive_resource(id:)
    set_doi(id)
  end

  field :models, ModelConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def models(**args)
    args[:resource_type_id] = "Model"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :model, ModelType, null: false do
    argument :id, ID, required: true
  end

  def model(id:)
    set_doi(id)
  end

  field :physical_objects, PhysicalObjectConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def physical_objects(**args)
    args[:resource_type_id] = "PhysicalObject"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :physical_object, PhysicalObjectType, null: false do
    argument :id, ID, required: true
  end

  def physical_object(id:)
    set_doi(id)
  end

  field :services, ServiceConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :pid_entity, String, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def services(**args)
    args[:resource_type_id] = "Service"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :service, ServiceType, null: false do
    argument :id, ID, required: true
  end

  def service(id:)
    set_doi(id)
  end

  field :softwares, SoftwareConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def softwares(**args)
    args[:resource_type_id] = "Software"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :software, SoftwareType, null: false do
    argument :id, ID, required: true
  end

  def software(id:)
    set_doi(id)
  end

  field :sounds, SoundConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def sounds(**args)
    args[:resource_type_id] = "Sound"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :sound, SoundType, null: false do
    argument :id, ID, required: true
  end

  def sound(id:)
    set_doi(id)
  end

  field :workflows, WorkflowConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def workflows(**args)
    args[:resource_type_id] = "Workflow"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :workflow, WorkflowType, null: false do
    argument :id, ID, required: true
  end

  def workflow(id:)
    set_doi(id)
  end

  field :dissertations, DissertationConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def dissertations(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "Dissertation,Thesis"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :dissertation, DissertationType, null: false do
    argument :id, ID, required: true
  end

  def dissertation(id:)
    set_doi(id)
  end

  field :data_management_plans, DataManagementPlanConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def data_management_plans(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "Data Management Plan"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :data_management_plan, DataManagementPlanType, null: false do
    argument :id, ID, required: true
  end

  def data_management_plan(id:)
    set_doi(id)
  end

  field :preprints, PreprintConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def preprints(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "PostedContent,Preprint"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :preprint, PreprintType, null: false do
    argument :id, ID, required: true
  end

  def preprint(id:)
    set_doi(id)
  end

  field :peer_reviews, PeerReviewConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def peer_reviews(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "\"Peer review\""
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :peer_review, PeerReviewType, null: false do
    argument :id, ID, required: true
  end

  def peer_review(id:)
    set_doi(id)
  end

  field :conference_papers, ConferencePaperConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def conference_papers(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "\"Conference paper\""
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :conference_paper, ConferencePaperType, null: false do
    argument :id, ID, required: true
  end

  def conference_paper(id:)
    set_doi(id)
  end

  field :book_chapters, BookChapterConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def book_chapters(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "BookChapter"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :book_chapter, BookChapterType, null: false do
    argument :id, ID, required: true
  end

  def book_chapter(id:)
    set_doi(id)
  end

  field :books, BookConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def books(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "Book"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :book, BookType, null: false do
    argument :id, ID, required: true
  end

  def book(id:)
    set_doi(id)
  end

  field :journal_articles, JournalArticleConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def journal_articles(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "JournalArticle"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :journal_article, JournalArticleType, null: false do
    argument :id, ID, required: true
  end

  def journal_article(id:)
    set_doi(id)
  end

  field :instruments, InstrumentConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def instruments(**args)
    args[:resource_type_id] = "Other"
    args[:resource_type] = "Instrument"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :instrument, InstrumentType, null: false do
    argument :id, ID, required: true
  end

  def instrument(id:)
    set_doi(id)
  end

  field :others, OtherConnectionWithTotalType, null: false do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :field_of_science_repository, String, required: false
    argument :field_of_science_combined, String, required: false
    argument :facet_count, Int, required: false, default_value: 10
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def others(**args)
    args[:resource_type_id] = "Other"
    ElasticsearchModelResponseConnection.new(response(**args), context: context, first: args[:first], after: args[:after])
  end

  field :other, OtherType, null: false do
    argument :id, ID, required: true
  end

  def other(id:)
    set_doi(id)
  end

  field :usage_reports, UsageReportConnectionWithTotalType, null: false, connection: true do
    argument :first, Int, required: false, default_value: 25
  end

  def usage_reports(first: nil)
    UsageReport.query(nil, page: { number: 1, size: first }).fetch(:data, [])
  end

  field :usage_report, UsageReportType, null: false do
    argument :id, ID, required: true
  end

  def usage_report(id:)
    result = UsageReport.find_by_id(id: id).fetch(:data, []).first
    fail ActiveRecord::RecordNotFound if result.nil?

    result
  end

  def response(**args)
    Doi.gql_query(
      args[:query],
      ids: args[:ids],
      user_id: args[:user_id],
      client_id: args[:repository_id],
      provider_id: args[:member_id],
      funder_id: args[:funder_id],
      resource_type_id: args[:resource_type_id],
      resource_type: args[:resource_type],
      published: args[:published],
      agency: args[:registration_agency],
      language: args[:language],
      license: args[:license],
      has_person: args[:has_person],
      has_funder: args[:has_funder],
      has_organization: args[:has_organization],
      has_affiliation: args[:has_affiliation],
      has_member: args[:has_member],
      has_citations: args[:has_citations],
      has_parts: args[:has_parts],
      has_versions: args[:has_versions],
      has_views: args[:has_views],
      has_downloads: args[:has_downloads],
      field_of_science: args[:field_of_science],
      field_of_science_repository: args[:field_of_science_repository],
      field_of_science_combined: args[:field_of_science_combined],
      facet_count: args[:facet_count],
      pid_entity: args[:pid_entity],
      state: "findable",
      page: {
        cursor: args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : [],
        size: args[:first]
      }
    )
  end

  def set_doi(id)
    doi = doi_from_url(id)
    fail ActiveRecord::RecordNotFound if doi.nil?

    result = ElasticsearchLoader.for(Doi).load(doi)
    fail ActiveRecord::RecordNotFound if result.nil?
  end
end
