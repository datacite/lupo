# frozen_string_literal: true

class PersonType < BaseObject
  extend_type

  field :datasets, PersonDatasetConnectionWithMetaType, null: true, description: "Authored datasets", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PersonPublicationConnectionWithMetaType, null: true, description: "Authored publications", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, PersonSoftwareConnectionWithMetaType, null: true, description: "Authored software", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(**args)
    ids = Event.query(nil, obj_id: https_to_http(object.uid || object.id), citation_type: "Dataset-Person").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, obj_id: https_to_http(object.uid || object.id), citation_type: "Person-ScholarlyArticle").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def softwares(**args)
    ids = Event.query(nil, obj_id: https_to_http(object.uid || object.id), citation_type: "Person-SoftwareSourceCode").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def https_to_http(url)
    orcid = orcid_from_url(url)
    return nil unless orcid.present?

    "https://orcid.org/#{orcid}"
  end
end
