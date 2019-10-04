# frozen_string_literal: true

class FunderType < BaseObject
  description "Information about funders"

  field :datasets, FunderDatasetConnectionWithMetaType, null: false, description: "Funded datasets", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, FunderPublicationConnectionWithMetaType, null: false, description: "Funded publications", connection: true do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, FunderSoftwareConnectionWithMetaType, null: false, description: "Funded software", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
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

  def softwares(**args)
    ids = Event.query(nil, obj_id: object[:id], citation_type: "Funder-SoftwareSourceCode").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end
end
