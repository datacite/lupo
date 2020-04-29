# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    extend_type

    field :members, Types::MemberConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def members(query: nil, year: nil, first: nil)
      Provider.query(query, year: year, page: { number: 1, size: first }).results.to_a
    end

    field :member, Types::MemberType, null: false do
      argument :id, ID, required: true
    end

    def member(id:)
      Provider.unscoped.where("allocator.role_name IN ('ROLE_FOR_PROFIT_PROVIDER', 'ROLE_CONTRACTUAL_PROVIDER', 'ROLE_CONSORTIUM' , 'ROLE_CONSORTIUM_ORGANIZATION', 'ROLE_ALLOCATOR', 'ROLE_ADMIN', 'ROLE_MEMBER', 'ROLE_REGISTRATION_AGENCY')").where(deleted_at: nil).where(symbol: id).first
    end

    field :repositories, Types::RepositoryConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :year, String, required: false
      argument :software, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def repositories(**args)
      Client.query(args[:query], year: args[:year], software: args[:software], page: { number: 1, size: args[:first] }).results.to_a
    end

    field :repository, Types::RepositoryType, null: false do
      argument :id, ID, required: true
    end

    def repository(id:)
      Client.where(symbol: id).where(deleted_at: nil).first
    end

    field :prefixes, Types::PrefixConnectionType, null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def prefixes(**args)
      Prefix.query(args[:query], page: { number: 1, size: args[:first] }).results.to_a
    end

    field :prefix, Types::PrefixType, null: false do
      argument :id, ID, required: true
    end

    def prefix(id:)
      Prefix.where(prefix: id).first
    end

    field :funders, Types::FunderConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def funders(**args)
      Funder.query(args[:query], limit: args[:first]).fetch(:data, [])
    end

    field :funder, Types::FunderType, null: false do
      argument :id, ID, required: true
    end

    def funder(id:)
      result = Funder.find_by_id(id).fetch(:data, []).first
      fail ActiveRecord::RecordNotFound if result.nil?

      result
    end

    field :data_catalog, Types::DataCatalogType, null: false do
      argument :id, ID, required: true
    end

    def data_catalog(id:)
      result = DataCatalog.find_by_id(id).fetch(:data, []).first
      fail ActiveRecord::RecordNotFound if result.nil?

      result
    end

    field :data_catalogs, Types::DataCatalogConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def data_catalogs(**args)
      DataCatalog.query(args[:query], limit: args[:first]).fetch(:data, [])
    end

    field :organizations, Types::OrganizationConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
    end

    def organizations(**args)
      Organization.query(args[:query]).fetch(:data, [])
    end

    field :organization, Types::OrganizationType, null: false do
      argument :id, ID, required: true
    end

    def organization(id:)
      result = Organization.find_by_id(id).fetch(:data, []).first
      fail ActiveRecord::RecordNotFound if result.nil?

      result
    end

    field :person, Types::PersonType, null: false do
      argument :id, ID, required: true
    end

    def person(id:)
      result = Person.find_by_id(id).fetch(:data, []).first
      fail ActiveRecord::RecordNotFound if result.nil?

      result
    end

    field :people, Types::PersonConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def people(**args)
      Person.query(args[:query], rows: args[:first]).fetch(:data, [])
    end

    field :works, Types::WorkConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :work, Types::WorkType, null: false do
      argument :id, ID, required: true
    end

    def work(id:)
      set_doi(id)
    end

    field :datasets, Types::DatasetConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :dataset, Types::DatasetType, null: false do
      argument :id, ID, required: true
    end

    def dataset(id:)
      set_doi(id)
    end

    field :publications, Types::PublicationConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :publication, Types::PublicationType, null: false do
      argument :id, ID, required: true
    end

    def publication(id:)
      set_doi(id)
    end

    field :audiovisuals, Types::AudiovisualConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :audiovisual, Types::AudiovisualType, null: false do
      argument :id, ID, required: true
    end

    def audiovisual(id:)
      set_doi(id)
    end

    field :collections, Types::CollectionConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :collection, Types::CollectionType, null: false do
      argument :id, ID, required: true
    end

    def collection(id:)
      set_doi(id)
    end

    field :data_papers, Types::DataPaperConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :data_paper, Types::DataPaperType, null: false do
      argument :id, ID, required: true
    end

    def data_paper(id:)
      set_doi(id)
    end

    field :events, Types::EventConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :event, Types::EventType, null: false do
      argument :id, ID, required: true
    end

    def event(id:)
      set_doi(id)
    end

    field :images, Types::ImageConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :image, Types::ImageType, null: false do
      argument :id, ID, required: true
    end

    def image(id:)
      set_doi(id)
    end

    field :interactive_resources, Types::InteractiveResourceConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :interactive_resource, Types::InteractiveResourceType, null: false do
      argument :id, ID, required: true
    end

    def interactive_resource(id:)
      set_doi(id)
    end

    field :models, Types::ModelConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :model, Types::ModelType, null: false do
      argument :id, ID, required: true
    end

    def model(id:)
      set_doi(id)
    end

    field :physical_objects, Types::PhysicalObjectConnectionType, null: false do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :physical_object, Types::PhysicalObjectType, null: false do
      argument :id, ID, required: true
    end

    def physical_object(id:)
      set_doi(id)
    end

    field :services, Types::ServiceConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :service, Types::ServiceType, null: false do
      argument :id, ID, required: true
    end

    def service(id:)
      set_doi(id)
    end

    field :softwares, Types::SoftwareConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :software, Types::SoftwareType, null: false do
      argument :id, ID, required: true
    end

    def software(id:)
      set_doi(id)
    end

    field :sounds, Types::SoundConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :sound, Types::SoundType, null: false do
      argument :id, ID, required: true
    end

    def sound(id:)
      set_doi(id)
    end

    field :workflows, Types::WorkflowConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :workflow, Types::WorkflowType, null: false do
      argument :id, ID, required: true
    end

    def workflow(id:)
      set_doi(id)
    end

    field :dissertations, Types::DissertationConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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

    def dissertations(**args)
      args[:resource_type_id] = "Text"
      args[:resource_type] = "Dissertation,Thesis"
      response(args)
    end

    field :dissertation, Types::DissertationType, null: false do
      argument :id, ID, required: true
    end

    def dissertation(id:)
      set_doi(id)
    end

    field :preprints, Types::PreprintConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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

    def preprints(**args)
      args[:resource_type_id] = "Text"
      args[:resource_type] = "PostedContent,Preprint"
      response(args)
    end

    field :preprint, Types::PreprintType, null: false do
      argument :id, ID, required: true
    end

    def preprint(id:)
      set_doi(id)
    end

    field :peer_reviews, Types::PeerReviewConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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

    def peer_reviews(**args)
      args[:resource_type_id] = "Text"
      args[:resource_type] = "\"Peer review\""
      response(args)
    end

    field :peer_review, Types::PeerReviewType, null: false do
      argument :id, ID, required: true
    end

    def peer_review(id:)
      set_doi(id)
    end

    field :conference_papers, Types::ConferencePaperConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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

    def conference_papers(**args)
      args[:resource_type_id] = "Text"
      args[:resource_type] = "\"Conference paper\""
      response(args)
    end

    field :conference_paper, Types::ConferencePaperType, null: false do
      argument :id, ID, required: true
    end

    def conference_paper(id:)
      set_doi(id)
    end

    field :book_chapters, Types::BookChapterConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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

    def book_chapters(**args)
      args[:resource_type_id] = "Text"
      args[:resource_type] = "BookChapter"
      response(args)
    end

    field :book_chapter, Types::BookChapterType, null: false do
      argument :id, ID, required: true
    end

    def book_chapter(id:)
      set_doi(id)
    end

    field :books, Types::BookConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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

    def books(**args)
      args[:resource_type_id] = "Text"
      args[:resource_type] = "Book"
      response(args)
    end

    field :book, Types::BookType, null: false do
      argument :id, ID, required: true
    end

    def book(id:)
      set_doi(id)
    end

    field :journal_articles, Types::JournalArticleConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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

    def journal_articles(**args)
      args[:resource_type_id] = "Text"
      args[:resource_type] = "JournalArticle"
      response(args)
    end

    field :journal_article, Types::JournalArticleType, null: false do
      argument :id, ID, required: true
    end

    def journal_article(id:)
      set_doi(id)
    end

    field :instruments, Types::InstrumentConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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

      response(args)
    end

    field :instrument, Types::InstrumentType, null: false do
      argument :id, ID, required: true
    end

    def instrument(id:)
      set_doi(id)
    end

    field :others, Types::OtherConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :query, String, required: false
      argument :ids, [String], required: false
      argument :user_id, String, required: false
      argument :repository_id, String, required: false
      argument :member_id, String, required: false
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
      response(args)
    end

    field :other, Types::OtherType, null: false do
      argument :id, ID, required: true
    end

    def other(id:)
      set_doi(id)
    end

    field :usage_reports, Types::UsageReportConnectionType, null: false, connection: true, max_page_size: 1000 do
      argument :first, Int, required: false, default_value: 25
    end

    def usage_reports(first: nil)
      UsageReport.query(nil, page: { number: 1, size: first }).fetch(:data, [])
    end

    field :usage_report, Types::UsageReportType, null: false do
      argument :id, ID, required: true
    end

    def usage_report(id:)
      result = UsageReport.find_by_id(id).fetch(:data, []).first
      fail ActiveRecord::RecordNotFound if result.nil?

      result
    end

    def response(**args)
      Doi.query(args[:query], ids: args[:ids], user_id: args[:user_id], client_id: args[:repository_id], provider_id: args[:member_id], resource_type_id: args[:resource_type_id], resource_type: args[:resource_type], has_person: args[:has_person], has_funder: args[:has_funder], has_organization: args[:has_organization], has_citations: args[:has_citations], has_parts: args[:has_parts], has_versions: args[:has_versions], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] }).results.to_a
    end

    def set_doi(id)
      doi = doi_from_url(id)
      fail ActiveRecord::RecordNotFound if doi.nil?

      result = ElasticsearchLoader.for(Doi).load(doi)
      fail ActiveRecord::RecordNotFound if result.nil?

      result
    end
  end
end
