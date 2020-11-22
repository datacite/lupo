# frozen_string_literal: true

require "rails_helper"

describe MediaController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "dois/1/media").to route_to(
        "media#index",
        datacite_doi_id: "1",
      )
    end

    it "routes to #show" do
      expect(get: "dois/1/media/1").to route_to(
        "media#show",
        datacite_doi_id: "1", id: "1",
      )
    end

    it "routes to #create" do
      expect(post: "dois/1/media").to route_to(
        "media#create",
        datacite_doi_id: "1",
      )
    end

    it "routes to #update via PUT" do
      expect(put: "dois/1/media/1").to route_to(
        "media#update",
        datacite_doi_id: "1", id: "1",
      )
    end

    it "routes to #update via PATCH" do
      expect(patch: "dois/1/media/1").to route_to(
        "media#update",
        datacite_doi_id: "1", id: "1",
      )
    end

    it "routes to #destroy" do
      expect(delete: "dois/1/media/1").to route_to(
        "media#destroy",
        datacite_doi_id: "1", id: "1",
      )
    end
  end
end
