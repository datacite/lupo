# frozen_string_literal: true

class OrganizationType < BaseObject
  description "Information about organizations"

  field :id, ID, null: true, description: "ROR ID"
  field :name, String, null: false, description: "The name of the organization."
  field :alternate_name, [String], null: true, description: "An alias for the organization."
  field :identifier, [IdentifierType], null: true, description: "The identifier(s) for the organization."
  field :url, [String], null: true, hash_key: "links", description: "URL of the organization."
  field :address, AddressType, null: true, description: "Physical address of the organization."

  field :datasets, OrganizationDatasetConnectionWithMetaType, null: false, description: "Datasets from this organization", connection: true, max_page_size: 1000 do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, OrganizationPublicationConnectionWithMetaType, null: false, description: "Publications from this organization", connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, OrganizationSoftwareConnectionWithMetaType, null: false, description: "Software from this organization", connection: true, max_page_size: 1000 do
    argument :first, Int, required: false, default_value: 25
  end

  field :researchers, OrganizationResearcherConnectionWithMetaType, null: false, description: "Researchers associated with this organization", connection: true, max_page_size: 1000 do
    argument :first, Int, required: false, default_value: 25
  end

  def alternate_name
    object.aliases + object.acronyms
  end

  def identifier
    Array.wrap(object.fund_ref).map { |o| { "name" => "fundRef", "value" => o } } + 
    Array.wrap(object.wikidata).map { |o| { "name" => "wikidata", "value" => o } } + 
    Array.wrap(object.grid).map { |o| { "name" => "grid", "value" => o } } + 
    Array.wrap(object.wikipedia_url).map { |o| { "name" => "wikipedia", "value" => o } }
  end

  def address
    { "type" => "postalAddress",
      "address_country" => object.country.fetch("name", nil) }
  end

  def datasets(**args)
    ids = Event.query(nil, obj_id: object.id, citation_type: "Dataset-Organization").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, obj_id: object.id, citation_type: "Organization-ScholarlyArticle").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def softwares(**args)
    ids = Event.query(nil, obj_id: object.id, citation_type: "Organization-SoftwareSourceCode").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def researchers(**args)
    ids = Event.query(nil, obj_id: object.id, citation_type: "Organization-Person").results.to_a.map do |e|
      orcid_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Researcher).load_many(ids)
  end
end
