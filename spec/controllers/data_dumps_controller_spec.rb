require 'rails_helper'

RSpec.describe DataDumpsController, type: :controller do

  let(:token) { User.generate_token }

  describe "GET #index" do
    it "returns http success" do
      request.headers["Authorization"] = "Bearer " + token
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    let(:data_dump) { create(:data_dump) }
    it "returns http success" do
      request.headers["Authorization"] = "Bearer " + token
      get :show, params: { id: data_dump.uid }
      expect(response).to have_http_status(:success)
    end
  end

end
