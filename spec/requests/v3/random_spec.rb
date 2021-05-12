# frozen_string_literal: true

require "rails_helper"

describe "random", type: :request do
  let(:token) { User.generate_token }
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + token,
    }
  end

  context "random string" do
    xit "creates a random string" do
      get "/v3/random", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["phrase"]).to be_present
    end
  end
end
