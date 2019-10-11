# frozen_string_literal: true

class PublicationType < BaseObject
  implements DoiItem
  implements MetricInterface

  field :datasets, PublicationDatasetConnectionWithMetaType, null: false, description: "Referenced datasets", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end
  field :publications, PublicationPublicationConnectionWithMetaType, null: false, description: "Referenced publications", connection: true do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end
  field :software_source_codes, PublicationSoftwareConnectionWithMetaType, null: false, description: "Referenced software", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "Dataset-ScholarlyArticle").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end
    
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "ScholarlyArticle-ScholarlyArticle").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def software_source_codes(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "ScholarlyArticle-SoftwareSourceCode").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end
end
