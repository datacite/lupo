# frozen_string_literal: true

class FunderType < BaseObject
  description "Information about funders"
  
  field :id, ID, null: false, description: "Crossref Funder ID"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, description: "The name of the funder."
  field :alternate_name, [String], null: true, description: "An alias for the funder."
  field :address, AddressType, null: true, description: "Physical address of the funder."
  field :datasets, FunderDatasetConnectionWithMetaType, null: false, description: "Funded datasets", connection: true, max_page_size: 1000 do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, FunderPublicationConnectionWithMetaType, null: false, description: "Funded publications", connection: true do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :software_source_codes, FunderSoftwareConnectionWithMetaType, null: false, description: "Funded software", connection: true, max_page_size: 1000 do
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Funder"
  end

  def address
    { "type" => "postalAddress",
      "address_country" => object.country.to_h.fetch("name", nil) }
  end

  def datasets(**args)
    ids = Event.query(nil, obj_id: object[:id], citation_type: "Dataset-Funder").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, obj_id: object[:id], citation_type: "Funder-ScholarlyArticle").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def software_source_codes(**args)
    ids = Event.query(nil, obj_id: object[:id], citation_type: "Funder-SoftwareSourceCode").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end
end
