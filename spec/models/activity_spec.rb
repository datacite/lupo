# frozen_string_literal: true

require "rails_helper"

describe Activity, type: :model do
  context "create doi" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client) }

    it "activity exists" do
      expect(doi.activities.length).to eq(1)
      activity = doi.activities.first
      expect(activity.auditable.uid).to eq(doi.uid)
      # expect(activity.username).to eq(2)
      expect(activity.request_uuid).to be_present
      expect(activity.audited_changes["aasm_state"]).to eq("draft")
      expect(activity.audited_changes["types"]).to eq(
        "bibtex" => "misc",
        "citeproc" => "dataset",
        "resourceType" => "DataPackage",
        "resourceTypeGeneral" => "Dataset",
        "ris" => "DATA",
        "schemaOrg" => "Dataset",
      )
    end
  end

  context "update doi" do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client) }

    it "activity exists" do
      doi.update(event: "publish")

      expect(doi.activities.length).to eq(2)
      activity = doi.activities.last
      expect(activity.auditable.uid).to eq(doi.uid)
      # expect(activity.username).to eq(2)
      expect(activity.request_uuid).to be_present
      expect(activity.audited_changes).to eq("aasm_state" => %w[draft findable])
    end
  end

  context "create provider" do
    let(:provider) { create(:provider) }

    it "activity exists" do
      expect(provider.activities.length).to eq(1)
      activity = provider.activities.first
      expect(activity.auditable.uid).to eq(provider.uid)

      expect(activity.request_uuid).to be_present
      expect(activity.audited_changes["non_profit_status"]).to eq("non-profit")
      expect(activity.audited_changes["display_name"]).to eq("My provider")
    end
  end

  context "update provider" do
    let(:provider) { create(:provider) }

    it "activity exists" do
      provider.update(non_profit_status: "for-profit")

      expect(provider.activities.length).to eq(2)
      activity = provider.activities.last
      expect(activity.auditable.uid).to eq(provider.uid)

      expect(activity.request_uuid).to be_present
      expect(activity.audited_changes).to eq(
        "non_profit_status" => %w[non-profit for-profit],
      )
    end
  end

  context "create client" do
    let(:client) { create(:client) }

    it "activity exists" do
      expect(client.activities.length).to eq(1)
      activity = client.activities.first
      expect(activity.auditable.uid).to eq(client.uid)

      expect(activity.request_uuid).to be_present
      expect(activity.audited_changes["client_type"]).to eq("repository")
      expect(activity.audited_changes["name"]).to eq("My data center")
    end
  end

  context "update client" do
    let(:client) { create(:client) }

    it "activity exists" do
      client.update(client_type: "periodical")

      expect(client.activities.length).to eq(2)
      activity = client.activities.last
      expect(activity.auditable.uid).to eq(client.uid)

      expect(activity.request_uuid).to be_present
      expect(activity.audited_changes).to eq("client_type" => %w[repository periodical])
    end
  end
end
