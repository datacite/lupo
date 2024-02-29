# frozen_string_literal: true

class PersonType < BaseObject
  implements ActorItem

  description "A person."

  field :given_name,
        String,
        null: true,
        description: "Given name. In the U.S., the first name of a person."
  field :family_name,
        String,
        null: true,
        description: "Family name. In the U.S., the last name of an person."
  field :description, String, null: true, description: "Biography of a Person."
  field :links,
        [LinkType],
        null: true,
        description: "The links to other relevant web pages about the person."
  field :identifiers,
        [IdentifierType],
        null: true, description: "The identifier(s) for the person."
  field :country,
        CountryType,
        null: true, description: "Country where the person is located."
  field :employment,
        [EmploymentType],
        null: true, description: "The employments of the person"
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
        null: true, description: "Authored datasets" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
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
        null: true, description: "Authored publications" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
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
        null: true, description: "Authored software" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
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
        null: true, description: "Authored works" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
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

  def works(**args)
    ElasticsearchModelResponseConnection.new(
      response(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def view_count
    args = { first: 0 }
    @r = response(**args) if @r.nil?
    @r.response.aggregations.view_count.value.to_i
  end

  def download_count
    args = { first: 0 }
    @r = response(**args) if @r.nil?
    @r.response.aggregations.download_count.value.to_i
  end

  def citation_count
    args = { first: 0 }
    @r = response(**args) if @r.nil?
    @r.response.aggregations.citation_count.value.to_i
  end

  def response(**args)
    Doi.gql_query(
      args[:query],
      ids: args[:ids],
      user_id: object[:id],
      client_id: args[:repository_id],
      provider_id: args[:member_id],
      affiliation_id: args[:affiliation_id],
      organization_id: args[:organization_id],
      resource_type_id: args[:resource_type_id],
      resource_type: args[:resource_type],
      agency: args[:registration_agency],
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
      license: args[:license],
      language: args[:language],
      state: "findable",
      page: {
        cursor:
          args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : [],
        size: args[:first],
      },
    )
  end
end
