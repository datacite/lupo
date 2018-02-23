require 'rails_helper'

describe Client, type: :model do
  let(:provider)  { create(:provider) }
  let(:client)  { create(:client, provider: provider) }
  let(:target) { create(:client, provider: provider, symbol: provider.symbol + ".TARGET") }
  let!(:dois) {  create_list(:doi, 5, client: client) }
  let!(:pony)  {  create(:provider, symbol: "LITTLE") }

  describe "Validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:contact_email) }
    it { should validate_presence_of(:contact_name) }
  end

  describe "to_jsonapi" do
    subject { create(:client, name: "Rainbow Dash", provider: pony, symbol: pony.symbol + ".PONY") }

    it "works" do
      params = subject.to_jsonapi
      expect(params.dig("data","attributes","contact-email")).not_to be_nil
      expect(params.dig("data","attributes","symbol")).to eq("LITTLE.PONY")
      expect(params.dig("data","attributes","prefixes")).not_to be_nil
    end
  end

  describe "methods" do
    it "should not update the symbol" do
      client.update_attributes :symbol => client.symbol+'foo.bar'
      expect(client.reload.symbol).to eq(client.symbol)
    end

    it "transfer all DOIs" do
      original_dois = Doi.where(client: client.symbol)
      expect(Doi.where(datacentre: client.id).count).to eq(5)
      expect(Doi.where(datacentre: target.id).count).to eq(0)
      client.target_id = target.symbol
      expect(Doi.where(datacentre: client.id).count).to eq(0)
      expect(Doi.where(datacentre: target.id).count).to eq(5)
    end
  end
end
