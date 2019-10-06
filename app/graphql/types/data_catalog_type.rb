# frozen_string_literal: true

class DataCatalogType < BaseObject
  extend_type

  key fields: 'id'

  field :id, ID, null: false, description: "Re3data identifier.", external: true

  field :datasets, DataCatalogDatasetConnectionWithMetaType, null: false, connection: true, max_page_size: 100, description: "Datasets hosted by the repository" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, DataCatalogPublicationConnectionWithMetaType, null: false, connection: true, max_page_size: 100, description: "Publications hosted by the repository" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, DataCatalogSoftwareConnectionWithMetaType, null: false, connection: true, max_page_size: 100, description: "Software hosted by the repository" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(**args)
    Doi.query(args[:query], re3data_id: doi_from_url(object[:id]), resource_type_id: "Dataset", page: { number: 1, size: args[:first] }).results.to_a
  end

  def publications(**args)
    Doi.query(args[:query], re3data_id: doi_from_url(object[:id]), resource_type_id: "Text", page: { number: 1, size: args[:first] }).results.to_a
  end

  def softwares(**args)
    Doi.query(args[:query], re3data_id: doi_from_url(object[:id]), resource_type_id: "Software", page: { number: 1, size: args[:first] }).results.to_a
  end
end
