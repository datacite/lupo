# frozen_string_literal: true

class ResearcherType < BaseObject
  description "Information about researchers"

  field :id, ID, null: true, description: "ORCID ID"
  field :name, String, null: true, description: "Researcher name"
  field :name_type, String, null: true, hash_key: "nameType", description: "The type of name"
  field :given_name, String, null: true, hash_key: "givenName", description: "Researcher given name"
  field :family_name, String, null: true, hash_key: "familyName", description: "Researcher family name"
  field :affiliation, [String], null: true, description: "Researcher affiliation"
  field :datasets, ResearcherDatasetConnectionWithMetaType, null: false, description: "Authored datasets", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, ResearcherPublicationConnectionWithMetaType, null: false, description: "Authored publications", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, ResearcherSoftwareConnectionWithMetaType, null: false, description: "Authored software", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  def id
    object.fetch(:id, nil) || object.fetch("nameIdentifiers", []).find { |n| n.fetch("nameIdentifierScheme", nil) == "ORCID" }.to_h.fetch("nameIdentifier", nil)
  end

  def datasets(**args)
    ids = Event.query(nil, obj_id: https_to_http(object[:id]), citation_type: "Dataset-Person").fetch(:data, []).map do |e|
      doi_from_url(e[:subj_id])
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def publications(**args)
    ids = Event.query(nil, obj_id: https_to_http(object[:id]), citation_type: "Person-ScholarlyArticle").fetch(:data, []).map do |e|
      doi_from_url(e[:subj_id])
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def softwares(**args)
    ids = Event.query(nil, obj_id: https_to_http(object[:id]), citation_type: "Person-SoftwareSourceCode").fetch(:data, []).map do |e|
      doi_from_url(e[:subj_id])
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end

  def https_to_http(url)
    uri = Addressable::URI.parse(url)
    uri.scheme = "http"
    uri.to_s
  end
end
