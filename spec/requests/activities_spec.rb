require "rails_helper"

describe "activities", type: :request do
  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
  let(:doi) { create(:doi, client: client) }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { "HTTP_ACCEPT"=>"application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer }}

  describe "activities for doi", elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }

    before do
      Doi.import
      Activity.import
      sleep 2
    end

    context "without username" do
      it "returns the activities" do
        get "/activities", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", 0, "attributes", "action")).to eq("create")
        expect(json.dig("data", 0, "attributes", "changes", "aasm_state")).to eq("draft")

        expect(json.dig("data", 0, "attributes", "prov:wasAttributedTo")).to be_nil
        expect(json.dig("data", 0, "attributes", "prov:wasGeneratedBy")).to be_present
        expect(json.dig("data", 0, "attributes", "prov:generatedAtTime")).to be_present
        expect(json.dig("data", 0, "attributes", "prov:wasDerivedFrom")).to be_present
      end
    end
  end
end
