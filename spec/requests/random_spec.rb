require "rails_helper"

describe "random", type: :request do
  let(:token) { User.generate_token }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + token } }

  context "random string" do
    it "creates a random string" do
      get "/random", params: nil, session: headers

      expect(last_response.status).to eq(200)
      expect(json["phrase"]).to be_present
    end
  end
end
