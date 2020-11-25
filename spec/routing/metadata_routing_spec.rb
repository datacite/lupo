# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetadataController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "dois/1/metadata").to route_to(
        "metadata#index",
        datacite_doi_id: "1",
      )
    end

    it "routes to #show" do
      expect(get: "dois/1/metadata/1").to route_to(
        "metadata#show",
        datacite_doi_id: "1", id: "1",
      )
    end

    it "routes to #create" do
      expect(post: "dois/1/metadata").to route_to(
        "metadata#create",
        datacite_doi_id: "1",
      )
    end

    it "routes to #update via PUT" do
      expect(put: "dois/1/metadata/1").to route_to(
        "metadata#update",
        datacite_doi_id: "1", id: "1",
      )
    end

    it "routes to #update via PATCH" do
      expect(patch: "dois/1/metadata/1").to route_to(
        "metadata#update",
        datacite_doi_id: "1", id: "1",
      )
    end

    it "routes to #destroy" do
      expect(delete: "dois/1/metadata/1").to route_to(
        "metadata#destroy",
        datacite_doi_id: "1", id: "1",
      )
    end
  end
end
