# frozen_string_literal: true

class OrganizationType < BaseObject
  description "Information about organizations"

  field :id, ID, null: true, description: "ROR ID"
  field :name, String, null: false, description: "Organization name"
  field :aliases, [String], null: true, description: "Aliases for organization name"
  field :acronyms, [String], null: true, description: "Acronyms for organization name"
  field :labels, [LabelType], null: true, description: "Labels for organization name"
  field :links, [String], null: true, description: "Links for organization"
  field :wikipedia_url, String, null: true, description: "Wikipedia URL for organization"
  field :country, CountryType, null: true, description: "Country where organization is located"
  field :isni, [String], null: true, description: "ISNI identifiers for organization"
  field :fund_ref, [String], null: true, description: "Crossref Funder ID identifiers for organization"
  field :wikidata, [String], null: true, description: "Wikidata identifiers for organization"
  field :grid, String, null: true, description: "GRID identifiers for organization"

  field :datasets, OrganizationDatasetConnectionWithMetaType, null: false, description: "Datasets from this organization", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, OrganizationPublicationConnectionWithMetaType, null: false, description: "Publications from this organization", connection: true do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, OrganizationSoftwareConnectionWithMetaType, null: false, description: "Software from this organization", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(**args)
    ids = Event.query(nil, obj_id: object[:id], citation_type: "Dataset-Organization").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, obj_id: object[:id], citation_type: "Organization-ScholarlyArticle").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def softwares(**args)
    ids = Event.query(nil, obj_id: object[:id], citation_type: "Organization-SoftwareSourceCode").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end
end
