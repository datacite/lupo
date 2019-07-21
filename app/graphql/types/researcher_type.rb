# frozen_string_literal: true

class ResearcherType < BaseObject
  description "Information about researchers"

  field :id, ID, null: true, description: "ORCID ID"
  field :name, String, null: true, description: "Researcher name"
  field :name_type, String, null: true, hash_key: "nameType", description: "The type of name"
  field :given_name, String, null: true, hash_key: "givenName", description: "Researcher given name"
  field :family_name, String, null: true, hash_key: "familyName", description: "Researcher family name"
  field :affiliation, [OrganizationType], null: true, description: "Researcher affiliation"
  field :datasets, ResearcherDatasetConnectionWithMetaType, null: true, description: "Authored datasets", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, ResearcherPublicationConnectionWithMetaType, null: true, description: "Authored publications", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, ResearcherSoftwareConnectionWithMetaType, null: true, description: "Authored software", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  def id
    object.uid ? "https://orcid.org/#{object.uid}" : object.id
  end

  def name
    object.name || object.fetch("name", nil)
  end

  def affiliation
    Array.wrap(object.fetch("affiliation", nil)).map do |a| 
      Hashie::Mash.new(a.merge("id" => a["affiliationIdentifier"]).except("affiliationIdentifier", "affiliationIdentifierScheme", "schemeUri"))
    end
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
