# frozen_string_literal: true

class PersonType < BaseObject
  description "A person."

  field :id, ID, null: true, description: "The ORCID ID of the person."
  field :name, String, null: true, description: "The name of the person."
  field :given_name, String, null: true, hash_key: "given_names", description: "Given name. In the U.S., the first name of a Person."
  field :family_name, String, null: true, description: "Family name. In the U.S., the last name of an Person."

  field :datasets, PersonDatasetConnectionWithMetaType, null: true, description: "Authored datasets", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PersonPublicationConnectionWithMetaType, null: true, description: "Authored publications", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, PersonSoftwareConnectionWithMetaType, null: true, description: "Authored software", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  def id
    object.uid ? "https://orcid.org/#{object.uid}" : object.id
  end

  def name
    object.name
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
