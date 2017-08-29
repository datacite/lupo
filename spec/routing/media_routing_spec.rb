require "rails_helper"

RSpec.describe MediaController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/media").to route_to("media#index")
    end


    it "routes to #show" do
      expect(:get => "/media/1").to route_to("media#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/media").to route_to("media#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/media/1").to route_to("media#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/media/1").to route_to("media#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/media/1").to route_to("media#destroy", :id => "1")
    end

  end
end
