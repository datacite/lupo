require 'rails_helper'

describe ProviderPrefix, type: :model do
  let(:prefix)  { create(:prefix, uid: "10.5083") }
  let(:provider_prefix)  { create(:provider_prefix, prefix: prefix) }

  it "is valid" do
    expect(provider_prefix.provider.name).to eq("My provider")
    expect(provider_prefix.prefix.uid).to eq("10.5083")
  end
end
