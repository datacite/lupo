require "rails_helper"

RSpec.describe MetadataController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/metadata").to route_to("metadata#index")
    end


    it "routes to #show" do
      expect(:get => "/metadata/1").to route_to("metadata#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/metadata").to route_to("metadata#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/metadata/1").to route_to("metadata#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/metadata/1").to route_to("metadata#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/metadata/1").to route_to("metadata#destroy", :id => "1")
    end

  end
end
