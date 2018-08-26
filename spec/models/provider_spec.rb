require 'rails_helper'

describe Provider, type: :model do
  let(:provider)  { create(:provider) }

  describe "validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:contact_email) }
    it { should validate_presence_of(:contact_name) }
    it { is_expected.to strip_attribute(:name) }
  end

  describe "admin" do
    subject { create(:provider, role_name: "ROLE_ADMIN", name: "Admin", symbol: "ADMIN") }

    it "works" do
      expect(subject.role_name).to eq("ROLE_ADMIN")
    end
  end

  # describe "prefixes" do
  #   let!(:prefix)  { create(:prefix, prefix: "10.5072") }

  #   it "set_test_prefix" do
  #     provider.send(:set_test_prefix)
  #     expect(provider.provider_prefixes.first).to be_valid
  #     expect(provider).to be_valid
  #   end
  # end

  describe "to_jsonapi" do
    it "works" do
      params = provider.to_jsonapi
      expect(params.dig("id")).to eq(provider.symbol.downcase)
      expect(params.dig("attributes","symbol")).to eq(provider.symbol)
      expect(params.dig("attributes","contact-email")).to eq(provider.contact_email)
      expect(params.dig("attributes","is-active")).to be true
    end
  end

  describe "password" do
    let(:password_input) { "Credible=Hangover8tighten" }
    subject { create(:provider, password_input: password_input) }

    it "should use password_input" do
      expect(subject.password).to eq(subject.encrypt_password_sha256(password_input))
    end

    it "should not use password_input when it is blank" do
      password_input = ""
      subject = create(:provider, password_input: password_input)
      expect(subject.password).to be_nil
    end
  end
end
