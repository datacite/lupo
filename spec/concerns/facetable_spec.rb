
# require 'rails_helper'

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
