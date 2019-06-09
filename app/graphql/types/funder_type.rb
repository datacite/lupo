# frozen_string_literal: true

class FunderType < BaseObject
  description "Information about funders"

  field :id, ID, null: false, description: "Crossref Funder ID"
  field :name, String, null: false, description: "Funder name"
  field :alternate_name, [String], null: true, description: "Alternate funder names"
  field :country, CountryType, null: true, description: "Country where funder is located"
  field :date_modified, String, null: false, description: "Date information was last updated"
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

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end
end
