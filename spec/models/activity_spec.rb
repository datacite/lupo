require "rails_helper"

describe Activity, type: :model do
  context "create doi" do
    let(:client)  { create(:client) }
    let(:doi) { create(:doi, client: client) }

    it "activity exists" do
      expect(doi.activities.length).to eq(1)
      activity = doi.activities.first
      expect(activity.uid).to eq(doi.uid)
      # expect(activity.username).to eq(2)
      expect(activity.request_uuid).to be_present
      expect(activity.changes["aasm_state"]).to eq("draft")
      expect(activity.changes["types"]).to eq("bibtex"=>"misc", "citeproc"=>"dataset", "resourceType"=>"DataPackage", "resourceTypeGeneral"=>"Dataset", "ris"=>"DATA", "schemaOrg"=>"Dataset")
    end
  end

  context "update doi" do
    let(:client)  { create(:client) }
    let(:doi) { create(:doi, client: client) }

    it "activity exists" do
      doi.update(event: "publish")

      expect(doi.activities.length).to eq(2)
      activity = doi.activities.last
      expect(activity.uid).to eq(doi.uid)
      # expect(activity.username).to eq(2)
      expect(activity.request_uuid).to be_present
      expect(activity.changes).to eq("aasm_state"=>["draft", "findable"])
    end
  end
end
