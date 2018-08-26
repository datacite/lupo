require 'rails_helper'

describe Client, type: :model do
  let(:provider)  { create(:provider) }
  let(:prefix)  { create(:prefix, prefix: "10.5072") }
  let(:client)  { create(:client, provider: provider) }
  let(:target) { create(:client, provider: provider, symbol: provider.symbol + ".TARGET") }

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

  # describe "prefixes" do
  #   it "set_test_prefix" do
  #     provider_prefix = create(:provider_prefix, provider: provider, prefix: prefix)
  #     client.send(:set_test_prefix)
  #     expect(client.client_prefixes.first).to be_valid
  #     expect(client).to be_valid
  #   end
  # end

  describe "methods" do
    it "should not update the symbol" do
      client.update_attributes :symbol => client.symbol+'foo.bar'
      expect(client.reload.symbol).to eq(client.symbol)
    end
  end

  describe "doi transfer", elasticsearch: true do
    let!(:dois) {  create_list(:doi, 5, client: client) }

    # it "transfer all DOIs" do
    #   original_dois = Doi.where(client: client.symbol)
    #   expect(Doi.where(datacentre: client.id).count).to eq(5)
    #   expect(Doi.where(datacentre: target.id).count).to eq(0)
    #   client.target_id = target.symbol
    #   client.save
    #   sleep 1
    #   expect(Doi.where(datacentre: client.id).count).to eq(0)
    #   expect(Doi.where(datacentre: target.id).count).to eq(5)
    # end
  end
end
