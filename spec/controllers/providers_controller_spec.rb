require 'rails_helper'

RSpec.describe ProvidersController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Provider. As you add validations to Provider, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ProvidersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      provider = Provider.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      provider = Provider.create! valid_attributes
      get :show, params: { id: provider.to_param }, session: valid_session
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Provider" do
        expect {
          post :create, params: { provider: valid_attributes }, session: valid_session
        }.to change(Provider, :count).by(1)
      end

      it "renders a JSON response with the new Provider" do

        post :create, params: { provider: valid_attributes }, session: valid_session
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
        expect(response.location).to eq(provider_url(Provider.last))
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new Provider" do

        post :create, params: {Provider: invalid_attributes}, session: valid_session
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested Provider" do
        provider = Provider.create! valid_attributes
        put :update, params: {id: provider.to_param, Provider: new_attributes}, session: valid_session
        provider.reload
        skip("Add assertions for updated state")
      end

      it "renders a JSON response with the Provider" do
        provider = Provider.create! valid_attributes

        put :update, params: {id: provider.to_param, Provider: valid_attributes}, session: valid_session
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the Provider" do
        provider = Provider.create! valid_attributes

        put :update, params: {id: provider.to_param, Provider: invalid_attributes}, session: valid_session
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested Provider" do
      provider = Provider.create! valid_attributes
      expect {
        delete :destroy, params: {id: provider.to_param}, session: valid_session
      }.to change(Provider, :count).by(-1)
    end
  end

end
