require "rails_helper"

RSpec.describe AllocatorsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/allocators").to route_to("allocators#index")
    end


    it "routes to #show" do
      expect(:get => "/allocators/1").to route_to("allocators#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/allocators").to route_to("allocators#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/allocators/1").to route_to("allocators#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/allocators/1").to route_to("allocators#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/allocators/1").to route_to("allocators#destroy", :id => "1")
    end

  end
end
