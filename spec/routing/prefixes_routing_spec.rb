require "rails_helper"

describe PrefixesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/prefixes").to route_to("prefixes#index")
    end

    it "routes to #show" do
      expect(get: "/prefixes/1").to route_to("prefixes#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/prefixes").to route_to("prefixes#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/prefixes/1").to route_to("prefixes#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/prefixes/1").to route_to("prefixes#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/prefixes/1").to route_to("prefixes#destroy", id: "1")
    end
  end
end
