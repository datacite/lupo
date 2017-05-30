require "rails_helper"

RSpec.describe DatacentresController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/datacentres").to route_to("datacentres#index")
    end


    it "routes to #show" do
      expect(:get => "/datacentres/1").to route_to("datacentres#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/datacentres").to route_to("datacentres#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/datacentres/1").to route_to("datacentres#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/datacentres/1").to route_to("datacentres#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/datacentres/1").to route_to("datacentres#destroy", :id => "1")
    end

  end
end
