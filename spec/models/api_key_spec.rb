# frozen_string_literal: true

require "rails_helper"

describe ApiKey, type: :model do
  let(:client) { create(:client, password_input: "12345") }

  describe "creation" do
    it "generates a key with prefix and stores only the hash" do
      api_key = client.api_keys.create!(name: "CI key")

      expect(api_key.key).to start_with("DC.")
      expect(api_key.key_prefix).to start_with("DC.")
      expect(api_key.key_hash).to be_present
      expect(api_key.key_hash).not_to eq(api_key.key)
      expect(api_key.revoked_at).to be_nil
      expect(api_key.id).to match(/\A[0-9a-f-]{36}\z/i)  # uuid
      expect(api_key.created_at).to be_present
    end
  end

  describe ".authenticate" do
    it "returns the key for valid token" do
      api_key = client.api_keys.create!(name: "test")
      plain = api_key.key

      found = ApiKey.authenticate(plain)
      expect(found).to eq(api_key)
    end

    it "returns nil for invalid token" do
      client.api_keys.create!(name: "test")
      expect(ApiKey.authenticate("DC.wrong")).to be_nil
    end

    it "does not authenticate revoked keys" do
      api_key = client.api_keys.create!(name: "test")
      api_key.revoke!

      expect(ApiKey.authenticate(api_key.key)).to be_nil
    end
  end

  describe "revoke" do
    it "soft revokes" do
      api_key = client.api_keys.create!(name: "to-revoke")
      api_key.revoke!
      expect(api_key.revoked?).to be true
      expect(ApiKey.active).not_to include(api_key)
    end
  end
end
