require 'rails_helper'

RSpec.describe Client, type: :model do
  let(:provider)  { create(:provider) }
  let(:client)  { create(:client, provider: provider) }
  let(:target) { create(:client, provider: provider, symbol: provider.symbol + ".TARGET") }
  let!(:dois) {  create_list(:doi, 5, client: client) }

  describe "Validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:contact_email) }
    it { should validate_presence_of(:contact_name) }
  end

  describe "methods" do
    it "should not update the symbol" do
      client.update_attributes :symbol => client.symbol+'foo.bar'
      expect(client.reload.symbol).to eq(client.symbol)
    end

    it "transfer all DOIS" do
      original_dois = Doi.where(client: client.symbol)
      expect(Doi.where(datacentre: client.id).count).to eq(5)
      expect(Doi.where(datacentre: target.id).count).to eq(0)
      client.target_id = target.symbol
      expect(Doi.where(datacentre: client.id).count).to eq(0)
      expect(Doi.where(datacentre: target.id).count).to eq(5)
    end
  end
end
