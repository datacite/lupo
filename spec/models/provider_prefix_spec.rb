require 'rails_helper'

describe ProviderPrefix, type: :model do
  let(:prefix) { create(:prefix, uid: "10.5083") }
  let(:provider) { create(:provider) }
  subject { create(:provider_prefix, prefix: prefix, provider: provider) }

  describe "Validations" do
    it { should validate_presence_of(:prefix) }
    it { should validate_presence_of(:provider) }
  end

  describe "methods" do
    it "is valid" do
      expect(subject.provider.name).to eq("My provider")
      expect(subject.prefix.uid).to eq("10.5083")
    end
  end
end
