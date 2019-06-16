# frozen_string_literal: true

class RepositoryType < BaseObject
  description "Information about repository"

  field :id, ID, null: false, description: "Repository ID"
  field :re3data_id, String, null: false, description: "re3data ID"
  field :name, String, null: false, description: "Repository name"
  field :additional_names, [TextLanguageType], null: false, description: "Additional repository names"
  field :url, String, null: true, description: "Repository URL"
  field :contacts, [TextType], null: true, description: "Repository contact information"
  field :description, String, null: true, description: "Repository description"
  field :certificates, [TextType], null: true, description: "Repository certificates"
  field :subjects, [SchemeType], null: true, description: "Subjects"
  field :types, [TextType], null: true, description: "Repository types"
  field :content_types, [SchemeType], null: true, description: "Content types"
  field :provider_types, [TextType], null: true, description: "Provider types"
  field :keywords, [TextType], null: true, description: "Keywords"
  field :data_accesses, [TextRestrictionType], null: true, description: "Data accesses"
  field :data_uploads, [TextRestrictionType], null: true, description: "Data uploads"
  field :pid_systems, [TextType], null: true, description: "PID Systems"
  field :apis, [ApiType], null: true, description: "APIs"
  field :software, [NameType], null: true, description: "Software"

  field :datasets, RepositoryDatasetConnectionWithMetaType, null: false, connection: true, max_page_size: 100, description: "Datasets hosted by the repository" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, RepositoryPublicationConnectionWithMetaType, null: false, connection: true, max_page_size: 100, description: "Publications hosted by the repository" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, RepositorySoftwareConnectionWithMetaType, null: false, connection: true, max_page_size: 100, description: "Software hosted by the repository" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(**args)
    Doi.query(args[:query], repository_id: doi_from_url(object[:id]), resource_type_id: "Dataset", page: { number: 1, size: args[:first] }).results.to_a
  end

  def publications(**args)
    Doi.query(args[:query], repository_id: doi_from_url(object[:id]), resource_type_id: "Text", page: { number: 1, size: args[:first] }).results.to_a
  end

  def softwares(**args)
    Doi.query(args[:query], repository_id: doi_from_url(object[:id]), resource_type_id: "Software", page: { number: 1, size: args[:first] }).results.to_a
  end
end
