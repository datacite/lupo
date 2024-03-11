# frozen_string_literal: true

class MemberType < BaseObject
  description "Information about members"

  field :id,
        ID,
        null: false,
        hash_key: "uid",
        description: "Unique identifier for the member"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, description: "Member name"
  field :displayName, String, null: false, description: "Member display name"
  field :ror_id,
        ID,
        null: true,
        description: "Research Organization Registry (ROR) identifier"
  field :description,
        String,
        null: true, description: "Description of the member"
  field :website, Url, null: true, description: "Website of the member"
  field :logo_url, Url, null: true, description: "URL for the member logo"
  field :region,
        String,
        null: true, description: "Geographic region where the member is located"
  field :country,
        CountryType,
        null: true, description: "Country where the member is located"
  field :member_role, MemberRoleType, null: true, description: "Membership type"
  field :organization_type,
        String,
        null: true, description: "Type of organization"
  field :focus_area,
        String,
        null: true, description: "Field of science covered by member"
  field :joined,
        GraphQL::Types::ISO8601Date,
        null: true, description: "Date member joined DataCite"
  field :view_count,
        Integer,
        null: true,
        description:
          "The number of views according to the Counter Code of Practice."
  field :download_count,
        Integer,
        null: true,
        description:
          "The number of downloads according to the Counter Code of Practice."
  field :citation_count,
        Integer,
        null: true, description: "The number of citations."

  field :datasets,
        DatasetConnectionWithTotalType,
        null: true, description: "Datasets by this provider." do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :publications,
        PublicationConnectionWithTotalType,
        null: true, description: "Publications by this provider." do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :softwares,
        SoftwareConnectionWithTotalType,
        null: true, description: "Software by this provider." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :data_management_plans,
        DataManagementPlanConnectionWithTotalType,
        null: true,
        description: "Data management plans from this organization" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :works,
        WorkConnectionWithTotalType,
        null: true, description: "Works by this provider." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :prefixes,
        MemberPrefixConnectionWithTotalType,
        null: true, description: "Prefixes managed by the member" do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :repositories,
        RepositoryConnectionWithTotalType,
        null: true, description: "Repositories associated with the member" do
    argument :year, String, required: false
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

  def type
    "Member"
  end

  def member_role
    { "id" => object.member_type, "name" => object.member_type.titleize }
  end

  def country
    return {} if object.country_code.blank?

    {
      id: object.country_code, name: ISO3166::Country[object.country_code].name
    }.compact
  end

  def publications(**args)
    args[:resource_type_id] = "Text"
    ElasticsearchModelResponseConnection.new(
      response(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    ElasticsearchModelResponseConnection.new(
      response(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def softwares(**args)
    args[:resource_type_id] = "Software"
    ElasticsearchModelResponseConnection.new(
      response(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def data_management_plans(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "Data Management Plan"
    ElasticsearchModelResponseConnection.new(
      response(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def works(**args)
    ElasticsearchModelResponseConnection.new(
      response(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def prefixes(**args)
    response =
      ProviderPrefix.query(
        args[:query],
        provider_id: object.uid,
        state: args[:state],
        year: args[:year],
        page: {
          cursor:
            args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : [],
          size: args[:first],
        },
      )
    ElasticsearchModelResponseConnection.new(
      response,
      context: context, first: args[:first], after: args[:after],
    )
  end

  def repositories(**args)
    response =
      ReferenceRepository.query(
        args[:query],
        provider_id: object.uid,
        year: args[:year],
        software: args[:software],
        page: {
          cursor:
            args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil,
          size: args[:first],
        },
      )
    ElasticsearchModelResponseConnection.new(
      response,
      context: context, first: args[:first], after: args[:after],
    )
  end

  def view_count
    args = { first: 0 }
    @r = response(**args) if @r.nil?
    if @r.results.total.positive?
      aggregate_count(@r.response.aggregations.views.buckets)
    else
      0
    end
  end

  def download_count
    args = { first: 0 }
    @r = response(**args) if @r.nil?
    if @r.results.total.positive?
      aggregate_count(@r.response.aggregations.downloads.buckets)
    else
      0
    end
  end

  def citation_count
    args = { first: 0 }
    @r = response(**args) if @r.nil?
    if @r.results.total.positive?
      aggregate_count(@r.response.aggregations.citations.buckets)
    else
      0
    end
  end

  def response(**args)
    Doi.gql_query(
      args[:query],
      ids: args[:ids],
      user_id: args[:user_id],
      client_id: args[:repository_id],
      provider_id: object.member_type == "consortium" ? nil : object.uid,
      consortium_id: object.member_type == "consortium" ? object.uid : nil,
      funder_id: args[:funder_id],
      affiliation_id: args[:affiliation_id],
      organization_id: args[:organization_id],
      resource_type_id: args[:resource_type_id],
      resource_type: args[:resource_type],
      has_person: args[:has_person],
      has_funder: args[:has_funder],
      has_affiliation: args[:has_affiliation],
      has_organization: args[:has_organization],
      has_citations: args[:has_citations],
      has_parts: args[:has_parts],
      has_versions: args[:has_versions],
      has_views: args[:has_views],
      has_downloads: args[:has_downloads],
      field_of_science: args[:field_of_science],
      published: args[:published],
      language: args[:language],
      license: args[:license],
      state: "findable",
      page: {
        cursor:
          args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : [],
        size: args[:first],
      },
    )
  end
end
