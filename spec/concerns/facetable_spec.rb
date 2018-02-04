
require 'rails_helper'

describe 'DataCenters', type: :controller do
  let(:provider) { create(:provider) }
  let(:model) { DataCentersController.new }
  let!(:clients)  { create_list(:client, 5, provider: provider) }
  let(:params)  { {year: 2008} }
  let(:params2)  { {year: clients.first.created.year} }


  describe "facet by year" do
    it "should return nothing" do
      facet = model.client_year_facet params, Client
      expect(facet.first[:count]).to eq(0)
    end
    it "should return all records" do
      client = clients.first
      facet = model.client_year_facet params2, Client
      expect(facet.first[:count]).to eq(5)
    end
  end
end
