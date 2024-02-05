# frozen_string_literal: true

class OrganizationType < BaseObject
  MEMBER_ROLES = {
    "ROLE_CONSORTIUM" => "consortium",
    "ROLE_CONSORTIUM_ORGANIZATION" => "consortium_organization",
    "ROLE_ALLOCATOR" => "direct_member",
    "ROLE_FOR_PROFIT_PROVIDER" => "for-profit_provider",
    "ROLE_MEMBER" => "member_only",
  }.freeze

  implements ActorItem

  description "Information about organizations"

  field :identifiers,
        [IdentifierType],
        null: true, description: "The identifier(s) for the organization."
  field :member_id,
        ID,
        null: true, description: "Unique member identifier if a DataCite member"
  field :member_role_id,
        String,
        null: true, description: "Membership role id if a DataCite member"
  field :member_role_name,
        String,
        null: true, description: "Membership role name if a DataCite member"
  field :url,
        [Url],
        null: true, hash_key: "links", description: "URL of the organization."
  field :wikipedia_url,
        Url,
        null: true,
        hash_key: "wikipedia_url",
        description: "Wikipedia URL of the organization."
  field :twitter,
        String,
        null: true, description: "Twitter username of the organization."
  field :types, [String], null: true, description: "The type of organization."
  field :country,
        CountryType,
        null: true, description: "Country of the organization."
  field :inception_year,
        Int,
        null: true,
        description: "Year when the organization came into existence."
  field :geolocation,
        GeolocationPointType,
        null: true, description: "Geolocation of the organization."
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
        null: true, description: "Datasets from this organization" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
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

  field :publications,
        PublicationConnectionWithTotalType,
        null: true, description: "Publications from this organization" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
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

  field :softwares,
        SoftwareConnectionWithTotalType,
        null: true, description: "Software from this organization" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
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
    argument :registration_agency, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
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

  field :works, WorkConnectionWithTotalType, null: true,
        description: "Works from this organization" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
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

  field :people,
        PersonConnectionWithTotalType,
        null: true, description: "People from this organization" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def alternate_name
    object.aliases + object.acronyms
  end

  def member
    m =
      Provider.unscoped.where(
        "allocator.role_name IN ('ROLE_FOR_PROFIT_PROVIDER', 'ROLE_CONSORTIUM' , 'ROLE_CONSORTIUM_ORGANIZATION', 'ROLE_ALLOCATOR', 'ROLE_MEMBER')",
      ).
        where(deleted_at: nil).
        where(ror_id: object.id).
        first
    return {} if m.blank?

    {
      "member_id" => m.symbol.downcase,
      "member_role_id" => MEMBER_ROLES[m.role_name],
      "member_role_name" => MEMBER_ROLES[m.role_name].titleize,
    }
  end

  def member_id
    member["member_id"]
  end

  def member_role_id
    member["member_role_id"]
  end

  def member_role_name
    member["member_role_name"]
  end

  def geolocation
    {
      "pointLongitude" => object.dig("geolocation", "longitude"),
      "pointLatitude" => object.dig("geolocation", "latitude"),
    }
  end

  def identifiers
    object.fundref.map do |o|
      { "identifierType" => "fundref", "identifier" => o }
    end +
      Array.wrap(object.wikidata).map do |o|
        { "identifierType" => "wikidata", "identifier" => o }
      end +
      Array.wrap(object.grid).map do |o|
        { "identifierType" => "grid", "identifier" => o }
      end +
      object.isni.map { |o| { "identifierType" => "isni", "identifier" => o } }
  end

  def publications(**args)
    args[:resource_type_id] = "Text"
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def softwares(**args)
    args[:resource_type_id] = "Software"
    ElasticsearchModelResponseConnection.new(
      response(args),
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
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def people(**args)
    grid_query = "grid-org-id:#{object.grid}"
    ringgold_query =
      object.ringgold.present? ? "ringgold-org-id:#{object.ringgold}" : ""
    org_query = [grid_query, ringgold_query].compact.join(" OR ")
    query_query = args[:query].present? ? "(#{args[:query]})" : nil
    query = ["(#{org_query})", query_query].compact.join(" AND ")

    response =
      Person.query(
        query,
        limit: args[:first],
        offset:
          args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : nil,
      )
    HashConnection.new(
      response,
      context: context, first: args[:first], after: args[:after],
    )
  end

  def view_count
    args = { first: 0 }
    @r = response(args) if @r.nil?
    @r.response.aggregations.view_count.value.to_i
  end

  def download_count
    args = { first: 0 }
    @r = response(args) if @r.nil?
    @r.response.aggregations.download_count.value.to_i
  end

  def citation_count
    args = { first: 0 }
    @r = response(args) if @r.nil?
    @r.response.aggregations.citation_count.value.to_i
  end

  def response(**args)
    Doi.gql_query(
      args[:query],
      ids: args[:ids],
      fair_organization_id: object.id,
      member_id:
        if %w[direct_member consortium_organization].include?(
          member["member_role_id"],
        )
          object.id
        end,
      published: args[:published],
      user_id: args[:user_id],
      client_id: args[:repository_id],
      funder_id: args[:funder_id] || object.fundref.join(","),
      resource_type_id: args[:resource_type_id],
      resource_type: args[:resource_type],
      agency: args[:registration_agency],
      language: args[:language],
      license: args[:license],
      has_person: args[:has_person],
      has_funder: args[:has_funder],
      has_citations: args[:has_citations],
      has_parts: args[:has_parts],
      has_versions: args[:has_versions],
      has_views: args[:has_views],
      has_downloads: args[:has_downloads],
      field_of_science: args[:field_of_science],
      field_of_science_repository: args[:field_of_science_repository],
      field_of_science_combined: args[:field_of_science_combined],
      facet_count: args[:facet_count],
      state: "findable",
      page: {
        cursor:
          args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : [],
        size: args[:first],
      },
    )
  end
end
