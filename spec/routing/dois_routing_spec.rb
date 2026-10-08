# frozen_string_literal: true

require "rails_helper"

describe DataciteDoisController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/dois").to route_to("datacite_dois#index")
    end

    it "routes to #show" do
      expect(get: "/dois/1").to route_to("datacite_dois#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/dois").to route_to("datacite_dois#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/dois/1").to route_to("datacite_dois#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/dois/1").to route_to("datacite_dois#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/dois/1").to route_to("datacite_dois#destroy", id: "1")
    end
  end
end
