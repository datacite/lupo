require "rails_helper"

RSpec.describe DoisController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/dois").to route_to("dois#index")
    end


    it "routes to #show" do
      expect(:get => "/dois/1").to route_to("dois#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/dois").to route_to("dois#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/dois/1").to route_to("dois#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/dois/1").to route_to("dois#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/dois/1").to route_to("dois#destroy", :id => "1")
    end

  end
end
