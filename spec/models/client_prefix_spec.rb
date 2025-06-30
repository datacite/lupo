# frozen_string_literal: true

require "rails_helper"

describe ClientPrefix, type: :model, elasticsearch: false, prefix_pool_size: 3 do
  context "Prefix assigned from the pool on repository creation" do
    let(:provider) { create(:provider) }
    let(:client) { create(:client, provider: provider) }
    let(:prefix) { client.prefixes.first }
    let(:provider_prefix) do
      create(:provider_prefix, prefix: prefix, provider: provider)
    end
    subject do
      create(
        :client_prefix,
        client: client, prefix: prefix, provider_prefix: provider_prefix,
      )
    end

    describe "Validations" do
      it { should validate_presence_of(:client) }
      it { should validate_presence_of(:prefix) }
      it { should validate_presence_of(:provider_prefix) }
    end

    describe "methods" do
      it "is valid" do
        expect(subject.client.name).to eq("My data center")
        expect(subject.prefix.uid).to eq(prefix.uid)
      end
    end
  end
end
