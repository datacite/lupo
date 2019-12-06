# frozen_string_literal: true

class PersonType < BaseObject
  description "A person."

  field :id, ID, null: true, description: "The ORCID ID of the person."
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: true, description: "The name of the person."
  field :given_name, String, null: true, hash_key: "given_names", description: "Given name. In the U.S., the first name of a Person."
  field :family_name, String, null: true, description: "Family name. In the U.S., the last name of an Person."

  field :datasets, PersonDatasetConnectionWithMetaType, null: true, description: "Authored datasets", connection: true do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PersonPublicationConnectionWithMetaType, null: true, description: "Authored publications", connection: true do
    argument :first, Int, required: false, default_value: 25
  end

  field :software_source_codes, PersonSoftwareConnectionWithMetaType, null: true, description: "Authored software", connection: true do
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Person"
  end

  def datasets(**args)
    ids = Event.query(nil, obj_id: https_to_http(object[:id]), citation_type: "Dataset-Person").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, obj_id: https_to_http(object[:id]), citation_type: "Person-ScholarlyArticle").results.to_a.map do |e|
      doi_from_url(e.subj_id)
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def software_source_codes(**args)
    ids = Event.query(nil, obj_id: https_to_http(object[:id]), citation_type: "Person-SoftwareSourceCode").results.to_a.map do |e|
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
