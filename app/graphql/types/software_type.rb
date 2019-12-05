# frozen_string_literal: true

class SoftwareType < BaseObject
  implements DoiItem
  implements MetricInterface

  field :datasets, SoftwareDatasetConnectionWithMetaType, null: false, description: "Referenced datasets", connection: true, max_page_size: 1000 do
    argument :first, Int, required: false, default_value: 25
  end
  field :publications, SoftwarePublicationConnectionWithMetaType, null: false, description: "Referenced publications", connection: true, max_page_size: 1000 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end
  field :software_source_codes, SoftwareSoftwareConnectionWithMetaType, null: false, description: "Referenced software", connection: true, max_page_size: 1000 do
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "Dataset-SoftwareSourceCode").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "ScholarlyArticle-SoftwareSourceCode").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def software_source_codes(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "SoftwareSourceCode-SoftwareSourceCode").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end
end
