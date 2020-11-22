# frozen_string_literal: true
# require 'rails_helper'
#
# RSpec.describe ClientsController, type: :controller do
#   describe "GET #index" do
#     let!(:clients) { create_list(:client, 5) }
#
#     it "returns a success response" do
#       client = Client.create! valid_attributes
#       get :index, {}
#       expect(response).to be_success
#     end
#   end
#
#   describe "GET #show" do
#     let(:client) { create(:client) }
#
#     it "returns a success response" do
#       client = Client.create! valid_attributes
#       get :show, {id: client.to_param}
#       expect(response).to be_success
#     end
#   end
#
#   describe "POST #create" do
#     context "with valid params" do
#       it "creates a new Client" do
#         expect {
#           post :create, {client: valid_attributes}, valid_session
#         }.to change(Client, :count).by(1)
#       end
#
#       it "renders a JSON response with the new client" do
#
#         post :create, {client: valid_attributes}, valid_session
#         expect(response).to have_http_status(:created)
#         expect(response.content_type).to eq('application/json')
#         expect(response.location).to eq(client_url(Client.last))
#       end
#     end
#
#     context "with invalid params" do
#       it "renders a JSON response with errors for the new client" do
#
#         post :create, {client: invalid_attributes}, valid_session
#         expect(response).to have_http_status(:unprocessable_entity)
#         expect(response.content_type).to eq('application/json')
#       end
#     end
#   end
#
#   describe "PUT #update" do
#     context "with valid params" do
#       let(:new_attributes) {
#         skip("Add a hash of attributes valid for your model")
#       }
#
#       it "updates the requested client" do
#         client = Client.create! valid_attributes
#         put :update, {id: client.to_param, client: new_attributes}, valid_session
#         client.reload
#         skip("Add assertions for updated state")
#       end
#
#       it "renders a JSON response with the client" do
#         client = Client.create! valid_attributes
#
#         put :update, {id: client.to_param, client: valid_attributes}, valid_session
#         expect(response).to have_http_status(:ok)
#         expect(response.content_type).to eq('application/json')
#       end
#     end
#
#     context "with invalid params" do
#       it "renders a JSON response with errors for the client" do
#         client = Client.create! valid_attributes
#
#         put :update, {id: client.to_param, client: invalid_attributes}, valid_session
#         expect(response).to have_http_status(:unprocessable_entity)
#         expect(response.content_type).to eq('application/json')
#       end
#     end
#   end
#
#   describe "DELETE #destroy" do
#     it "destroys the requested client" do
#       client = Client.create! valid_attributes
#       expect {
#         delete :destroy, {id: client.to_param}, valid_session
#       }.to change(Client, :count).by(-1)
#     end
#   end
#
# end
