require "rails_helper"

describe RepositoriesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/repositories").to route_to("repositories#index")
    end

    it "routes to #show" do
      expect(get: "/repositories/1").to route_to("repositories#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/repositories").to route_to("repositories#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/repositories/1").to route_to("repositories#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/repositories/1").to route_to("repositories#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/repositories/1").to route_to("repositories#destroy", id: "1")
    end
  end
end
