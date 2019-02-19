require 'rails_helper'

describe Client, type: :model do
  let(:provider)  { create(:provider) }
  let(:client)  { create(:client, provider: provider) }

  describe "Validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:contact_email) }
    it { should validate_presence_of(:contact_name) }
    it { is_expected.to strip_attribute(:name) }
    it { is_expected.to strip_attribute(:domains) }
  end

  describe "to_jsonapi" do
    it "works" do
      params = client.to_jsonapi
      expect(params.dig("id")).to eq(client.symbol.downcase)
      expect(params.dig("attributes","symbol")).to eq(client.symbol)
      expect(params.dig("attributes","contact-email")).to eq(client.contact_email)
      expect(params.dig("attributes","provider-id")).to eq(client.provider_id)
      expect(params.dig("attributes","is-active")).to be true
    end
  end

  describe "methods" do
    it "should not update the symbol" do
      client.update_attributes :symbol => client.symbol+'foo.bar'
      expect(client.reload.symbol).to eq(client.symbol)
    end
  end
end
