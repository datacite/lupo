require 'rails_helper'

RSpec.describe "Metadata", type: :request do
  describe "GET /metadata" do
    it "works! (now write some real specs)" do
      get metadata_index_path
      expect(response).to have_http_status(200)
    end
  end
end
