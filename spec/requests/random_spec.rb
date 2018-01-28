require 'rails_helper'

describe "random", type: :request  do
  let(:token) { User.generate_token }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + token } }

  context 'random string' do

    before { get '/random', headers: headers }

    it 'creates a random string' do
      expect(json['phrase']).to be_present
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
