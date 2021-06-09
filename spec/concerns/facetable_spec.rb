# frozen_string_literal: true
require 'rails_helper'

describe "Facetable", type: :controller do
    let(:author_aggs) { JSON.parse(file_fixture("authors_aggs.json").read) }
    let(:model) { DataciteDoisController.new }
    it "facet by author" do
        authors = model.facet_by_authors(author_aggs)

        expected_result = [{"id"=>"https://orcid.org/0000-0003-1419-2405", "title"=>"Fenner, Martin", "count"=>244}, {"id"=>"https://orcid.org/0000-0001-9570-8121", "title"=>"Lambert, Simon", "count"=>23}]
        expect(authors).to eq (expected_result)
    end

  end


# describe 'Clients', type: :controller do
#   let(:provider) { create(:provider) }
#   let(:model) { ClientsController.new }
#   let!(:clients)  { create_list(:client, 5, provider: provider) }
#   let(:params)  { {year: 2008} }
#   let(:params2)  { {year: clients.first.created.year} }

#   # describe "facet by year" do
#   #   before do
#   #     Provider.create(provider)
#   #     clients.each { |item| Client.create(item) }
#   #     sleep 2
#   #   end

#   #   it "should return nothing" do
#   #     puts Client.all
#   #     facet = model.facet_by_year params, Client.all
#   #     puts facet.class.name
#   #     puts facet.inspect
#   #     puts "chchc"
#   #     expect(facet.first[:count]).to eq(0)
#   #   end

#   #   it "should return all records" do
#   #     facet = model.facet_by_year params2, Client.all
#   #     puts facet
#   #     expect(facet.first[:count]).to eq(5)
#   #   end
#   # end
# end
