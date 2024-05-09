# frozen_string_literal: true

class FunderType < BaseObject
  implements ActorItem

  description "Information about funders"

  field :address,
        AddressType,
        null: true, description: "Physical address of the funder."
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
        null: true, description: "Funded datasets" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
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
        null: true, description: "Funded publications" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
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
        null: true, description: "Funded software" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
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
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
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
        null: true, description: "Funded works" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def address
    {
      "type" => "postalAddress",
      "country" => object.country.to_h.fetch("name", nil),
    }
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
      funder_id: object.id,
      user_id: args[:user_id],
      client_id: args[:repository_id],
      provider_id: args[:member_id],
      affiliation_id: args[:affiliation_id],
      organization_id: args[:organization_id],
      resource_type_id: args[:resource_type_id],
      resource_type: args[:resource_type],
      agency: args[:registration_agency],
      language: args[:language],
      license: args[:license],
      has_person: args[:has_person],
      has_organization: args[:has_organization],
      has_affiliation: args[:has_affiliation],
      has_member: args[:has_member],
      has_citations: args[:has_citations],
      has_parts: args[:has_parts],
      has_versions: args[:has_versions],
      has_views: args[:has_views],
      has_downloads: args[:has_downloads],
      field_of_science: args[:field_of_science],
      published: args[:published],
      state: "findable",
      page: {
        cursor:
          args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : [],
        size: args[:first],
      },
    )
  end
end
