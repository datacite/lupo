# frozen_string_literal: true

class DatasetType < BaseObject
  implements DoiItem
  implements MetricInterface

  field :usage_reports, DatasetUsageReportConnectionWithMetaType, null: false, description: "Usage reports for this dataset", connection: true do
    argument :first, Int, required: false, default_value: 25
  end
  field :datasets, DatasetDatasetConnectionWithMetaType, null: false, description: "Referenced datasets", connection: true do
    argument :first, Int, required: false, default_value: 25
  end
  field :publications, DatasetPublicationConnectionWithMetaType, null: false, description: "Referenced publications", connection: true do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end
  field :software_source_codes, DatasetSoftwareConnectionWithMetaType, null: false, description: "Referenced software", connection: true do
    argument :first, Int, required: false, default_value: 25
  end

  def usage_reports(**args)
    ids = Event.query(nil, obj_id: object.id).results.to_a.map do |e|
      e[:subj_id]
    end
    UsageReport.find_by_id(ids, page: { number: 1, size: args[:first] }).fetch(:data, [])
  end

  def datasets(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "Dataset-Dataset").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end

    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "Dataset-ScholarlyArticle").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def software_source_codes(**args)
    ids = Event.query(nil, doi: doi_from_url(object.identifier), citation_type: "Dataset-SoftwareSourceCode").results.to_a.map do |e|
      object.identifier == e.subj_id ? doi_from_url(e.obj_id) : doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end
end
