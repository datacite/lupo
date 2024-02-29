
# frozen_string_literal: true

class RepositoryType < BaseObject
  description "Information about repositories"
  field :uid,
        ID,
        null: false,
        description: "Unique identifier for each repository"
  field :type,
        String,
        null: false,
        description: "The type of the item."
  field :client_id,
        ID,
        null: true,
        description: "The unique identifier for the client repository"
  field :re3data_doi,
        ID,
        hash_key: "re3doi",
        null: true, description: "The re3data doi for the repository"
  field :name,
        String,
        null: false,
        description: "Repository name"
  field :alternate_name,
        [String],
        null: true,
        description: "Repository alternate names"
  field :description,
        String,
        null: true,
        description: "Description of the repository"
  field :url,
        Url,
        null: true,
        description: "The homepage of the repository"
  field :re3data_url,
        Url,
        null: true,
        description: "URL of the data catalog."
  field :software,
        [String],
        null: true,
        description: "The name of the software that is used to run the repository"
  field :repository_type,
        [String],
        null: true,
        description: "The repository type(s)"
  field :certificate,
        [String],
        null: true,
        description: "The certificate(s) for the repository"
  field :keyword,
        [String],
        null: true,
        description: "The language of the repository"
  field :language,
        [String],
        null: true,
        description: "The language of the repository"
  field :provider_type,
        [String],
        null: true,
        description: "The type(s) of Provider"
  field :pid_system,
        [String],
        null: true,
        description: "PID Systems"
  field :data_access,
        [TextRestrictionType],
        null: true,
        description: "Data accesses"
  field :data_upload,
        [TextRestrictionType],
        null: true,
        description: "Data uploads"
  field :subject,
        [DefinedTermType],
        null: true,
        description: "Subject areas covered by the data catalog."
  field :contact,
        [String],
        null: true,
        description: "Repository contact information"

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
        null: true,
        description: "The number of citations."

  field :works,
        WorkConnectionWithTotalType,
        null: true,
        description: "Works managed by the repository" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
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
    argument :has_member, Boolean, required: false
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

  field :datasets,
        DatasetConnectionWithTotalType,
        null: true, description: "Datasets managed by the repository" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
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
        null: true, description: "Publications managed by the repository" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
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
        null: true, description: "Software managed by the repository" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :member_id, String, required: false
    argument :registration_agency, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :license, String, required: false
    argument :resource_type, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
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
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_member, Boolean, required: false
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
        RepositoryPrefixConnectionWithTotalType,
        null: true, description: "Prefixes managed by the repository" do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def type
    "Repository"
  end

  def subject
    Array.wrap(object.subject).map { |sub|
      {
        term_code: sub.id,
        name: sub.text,
        in_defined_term_set: sub.scheme
      }
    }
  end

  def works(**args)
    ElasticsearchModelResponseConnection.new(
      dois(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    ElasticsearchModelResponseConnection.new(
      dois(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def publications(**args)
    args[:resource_type_id] = "Text"
    ElasticsearchModelResponseConnection.new(
      dois(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def softwares(**args)
    args[:resource_type_id] = "Software"
    ElasticsearchModelResponseConnection.new(
      dois(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def data_management_plans(**args)
    args[:resource_type_id] = "Text"
    args[:resource_type] = "Data Management Plan"
    ElasticsearchModelResponseConnection.new(
      dois(**args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def prefixes(**args)
    response =
      ClientPrefix.query(
        args[:query],
        client_id: object.client_id,
        state: args[:state],
        year: args[:year],
        page: { number: 1, size: args[:first] },
      )
    ElasticsearchModelResponseConnection.new(
      response,
      context: context, first: args[:first], after: args[:after],
    )
  end

  def view_count
    args = { first: 0 }
    @r = dois(**args) if @r.nil?
    @r.response.aggregations.view_count.value.to_i
  end

  def download_count
    args = { first: 0 }
    @r = dois(**args) if @r.nil?
    @r.response.aggregations.download_count.value.to_i
  end

  def citation_count
    args = { first: 0 }
    @r = dois(**args) if @r.nil?
    @r.response.aggregations.citation_count.value.to_i
  end

  def dois(**args)
    rr_query_parts = []
    if object.client_id
      rr_query_parts << "client_id:#{object.client_id}"
    end
    if object.re3doi
      rr_query_parts << "re3data_id:#{object.re3doi}"
    end
    rr_query_scope = rr_query_parts.join(" OR ")
    if args[:query].present?
      query = args.fetch(:query, "") + " AND (#{rr_query_scope})"
    else
      query = rr_query_scope
    end

    Doi.gql_query(
      query,
      funder_id: args[:funder_id],
      user_id: args[:user_id],
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
      has_funder: args[:has_funder],
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
