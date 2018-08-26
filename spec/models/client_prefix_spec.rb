require 'rails_helper'

describe ClientPrefix, type: :model do
  let(:prefix)  { create(:prefix, prefix: "10.5083") }
  let(:client_prefix)  { create(:client_prefix, prefix: prefix) }

  it "is valid" do
    expect(client_prefix.client.name).to eq("My data center")
    expect(client_prefix.prefix.prefix).to eq("10.5083")
  end
end
