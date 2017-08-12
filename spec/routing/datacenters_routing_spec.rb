require "rails_helper"

RSpec.describe DatacentersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/data-centers").to route_to("datacenters#index")
    end


    it "routes to #show" do
      expect(:get => "/data-centers/1").to route_to("datacenters#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/data-centers").to route_to("datacenters#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/data-centers/1").to route_to("datacenters#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/data-centers/1").to route_to("datacenters#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/data-centers/1").to route_to("datacenters#destroy", :id => "1")
    end
  end
end
