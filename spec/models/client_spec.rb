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

  describe "issn" do
    let(:client)  { build(:client, provider: provider, client_type: "periodical") }

    it "should support issn" do
      client.issn = { "issnl" => "1544-9173" }
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should support multiple issn" do
      client.issn = { "electronic" => "1544-9173", "print" => "1545-7885" }
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should reject invalid issn" do
      client.issn = { "issnl" => "1544-91XX" }
      expect(client.save).to be false
      expect(client.errors.details).to eq(:issn=>[{:error=>"ISSN-L 1544-91XX is in the wrong format."}])
    end
  end

  describe "certificate" do
    let(:client)  { build(:client, provider: provider, client_type: "repository") }

    it "should support certificate" do
      client.certificate = ["CoreTrustSeal"]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should support multiple certificates" do
      client.certificate = ["WDS", "DSA"]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should reject unknown certificate" do
      client.certificate = ["MyHomeGrown Certificate"]
      expect(client.save).to be false
      expect(client.errors.details).to eq(:certificate=>[{:error=>"Certificate MyHomeGrown Certificate is not included in the list of supported certificates."}])
    end
  end

  describe "repository_type" do
    let(:client)  { build(:client, provider: provider, client_type: "repository") }

    it "should support repository_type" do
      client.repository_type = ["institutional"]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should support multiple repository_types" do
      client.repository_type = ["institutional", "governmental"]
      expect(client.save).to be true
      expect(client.errors.details).to be_empty
    end

    it "should reject unknown repository_type" do
      client.repository_type = ["interplanetary"]
      expect(client.save).to be false
      expect(client.errors.details).to eq(:repository_type=>[{:error=>"Repository type interplanetary is not included in the list of supported repository types."}])
    end
  end
end
