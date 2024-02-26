# frozen_string_literal: true

require "rails_helper"

describe Metadata, type: :model, vcr: true do
  let(:provider) { create(:provider, symbol: "ADMIN") }
  let(:client) { create(:client, provider: provider) }
  let(:doi) { create(:doi, client: client) }
  let(:xml) { file_fixture('datacite.xml').read }

  context "validations" do
    it { should validate_presence_of(:xml) }
    it { should validate_presence_of(:namespace) }
  end

  describe 'associations' do
    it { should belong_to(:doi).with_foreign_key(:dataset).inverse_of(:metadata) }
  end

  describe 'before_validation callbacks' do
    let(:metadata) { build(:metadata, doi: doi, xml: xml) }

    it 'sets the namespace before validation' do
      metadata.valid?
      expect(metadata.namespace).not_to be_nil
    end

    it 'sets the metadata version before validation' do
      metadata.valid?
      expect(metadata.metadata_version).to eq(1)
    end
  end

  describe '#uid' do
    let(:metadata) { Metadata.create(xml: xml, doi: doi)}

    it 'generates a uid for the metadata' do
      expect(metadata.uid).not_to be_nil
    end
  end

  describe '#client_id' do
    let(:metadata) { build(:metadata, doi: doi, xml: xml) }

    it 'returns the client ID' do
      expect(metadata.client_id).to eq(client.symbol.downcase)
    end
  end

  describe '#metadata_must_be_valid' do
    context 'with invalid XML' do
      let(:xml) { 'invalid xml' }
      let(:metadata) { build(:metadata, doi: doi) }
      it 'adds errors if XML is invalid' do
        metadata.valid?
        expect(metadata.errors[:xml]).not_to be_empty
      end
    end

    context 'with valid XML' do
      let(:xml) { file_fixture('datacite.xml').read }
      let(:metadata) { build(:metadata, doi: doi, xml: xml) }

      it 'does not add errors if XML is valid' do
        metadata.valid?
        expect(metadata.errors[:xml]).to be_empty
      end
    end
  end

  describe '#doi_id=' do
    let(:metadata) { build(:metadata) }

    it 'sets the dataset attribute with the DOI id' do
      metadata.doi_id = doi.doi
      expect(metadata.dataset).to eq(doi.id)
    end

    it 'raises ActiveRecord::RecordNotFound if DOI is not found' do
      expect { metadata.doi_id = 'invalid_doi' }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "parses xml" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: client) }
    let(:xml) { file_fixture("datacite.xml").read }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      expect(subject.xml).to eq(xml)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-4")
    end

    it "creates metadata_version" do
      expect(subject.metadata_version).to eq(1)
    end

    it "creates doi association" do
      expect(subject.doi.doi).to eq(doi.doi)
    end
  end

  context "parses xml namespaces" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: client) }
    let(:xml) { file_fixture("ns0.xml").read }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      expect(subject.xml).to eq(xml)
    end

    it "valid model" do
      expect(subject.valid?).to be true
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-2.2")
    end

    it "creates metadata_version" do
      expect(subject.metadata_version).to eq(1)
    end

    it "creates doi association" do
      expect(subject.doi.doi).to eq(doi.doi)
    end
  end

  context "parses invalid xml draft state" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: client, xml: nil) }
    let(:xml) { file_fixture("datacite_missing_creator.xml").read }

    subject { Metadata.create(xml: xml, doi: doi) }

    it "creates xml" do
      expect(subject.xml).to eq(xml)
    end

    it "creates namespace" do
      expect(subject.namespace).to eq("http://datacite.org/schema/kernel-4")
    end

    # TODO: db-fields-for-attributes
    # it "valid model" do
    #   expect(subject.valid?).to be false
    # end

    it "validates xml" do
      expect(subject.errors[:xml]).to be_empty
    end
  end

  # context "parses invalid xml findable state" do
  #   let(:provider)  { create(:provider, symbol: "ADMIN") }
  #   let(:client)  { create(:client, provider: provider) }
  #   let(:doi) { create(:doi, client: client, aasm_state: "findable", xml: nil) }
  #   let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHJlc291cmNlIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhtbG5zPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCBodHRwOi8vc2NoZW1hLmRhdGFjaXRlLm9yZy9tZXRhL2tlcm5lbC00L21ldGFkYXRhLnhzZCI+CiAgPGlkZW50aWZpZXIgaWRlbnRpZmllclR5cGU9IkRPSSI+MTAuNTQzOC80SzNNLU5ZVkc8L2lkZW50aWZpZXI+CiAgPGNyZWF0b3JzLz4KICA8dGl0bGVzPgogICAgPHRpdGxlPkVhdGluZyB5b3VyIG93biBEb2cgRm9vZDwvdGl0bGU+CiAgPC90aXRsZXM+CiAgPHB1Ymxpc2hlcj5EYXRhQ2l0ZTwvcHVibGlzaGVyPgogIDxwdWJsaWNhdGlvblllYXI+MjAxNjwvcHVibGljYXRpb25ZZWFyPgogIDxyZXNvdXJjZVR5cGUgcmVzb3VyY2VUeXBlR2VuZXJhbD0iVGV4dCI+QmxvZ1Bvc3Rpbmc8L3Jlc291cmNlVHlwZT4KICA8YWx0ZXJuYXRlSWRlbnRpZmllcnM+CiAgICA8YWx0ZXJuYXRlSWRlbnRpZmllciBhbHRlcm5hdGVJZGVudGlmaWVyVHlwZT0iTG9jYWwgYWNjZXNzaW9uIG51bWJlciI+TVMtNDktMzYzMi01MDgzPC9hbHRlcm5hdGVJZGVudGlmaWVyPgogIDwvYWx0ZXJuYXRlSWRlbnRpZmllcnM+CiAgPHN1YmplY3RzPgogICAgPHN1YmplY3Q+ZGF0YWNpdGU8L3N1YmplY3Q+CiAgICA8c3ViamVjdD5kb2k8L3N1YmplY3Q+CiAgICA8c3ViamVjdD5tZXRhZGF0YTwvc3ViamVjdD4KICA8L3N1YmplY3RzPgogIDxkYXRlcz4KICAgIDxkYXRlIGRhdGVUeXBlPSJDcmVhdGVkIj4yMDE2LTEyLTIwPC9kYXRlPgogICAgPGRhdGUgZGF0ZVR5cGU9Iklzc3VlZCI+MjAxNi0xMi0yMDwvZGF0ZT4KICAgIDxkYXRlIGRhdGVUeXBlPSJVcGRhdGVkIj4yMDE2LTEyLTIwPC9kYXRlPgogIDwvZGF0ZXM+CiAgPHJlbGF0ZWRJZGVudGlmaWVycz4KICAgIDxyZWxhdGVkSWRlbnRpZmllciByZWxhdGVkSWRlbnRpZmllclR5cGU9IkRPSSIgcmVsYXRpb25UeXBlPSJSZWZlcmVuY2VzIj4xMC41NDM4LzAwMTI8L3JlbGF0ZWRJZGVudGlmaWVyPgogICAgPHJlbGF0ZWRJZGVudGlmaWVyIHJlbGF0ZWRJZGVudGlmaWVyVHlwZT0iRE9JIiByZWxhdGlvblR5cGU9IlJlZmVyZW5jZXMiPjEwLjU0MzgvNTVFNS1UNUMwPC9yZWxhdGVkSWRlbnRpZmllcj4KICAgIDxyZWxhdGVkSWRlbnRpZmllciByZWxhdGVkSWRlbnRpZmllclR5cGU9IkRPSSIgcmVsYXRpb25UeXBlPSJJc1BhcnRPZiI+MTAuNTQzOC8wMDAwLTAwU1M8L3JlbGF0ZWRJZGVudGlmaWVyPgogIDwvcmVsYXRlZElkZW50aWZpZXJzPgogIDx2ZXJzaW9uPjEuMDwvdmVyc2lvbj4KICA8ZGVzY3JpcHRpb25zPgogICAgPGRlc2NyaXB0aW9uIGRlc2NyaXB0aW9uVHlwZT0iQWJzdHJhY3QiPkVhdGluZyB5b3VyIG93biBkb2cgZm9vZCBpcyBhIHNsYW5nIHRlcm0gdG8gZGVzY3JpYmUgdGhhdCBhbiBvcmdhbml6YXRpb24gc2hvdWxkIGl0c2VsZiB1c2UgdGhlIHByb2R1Y3RzIGFuZCBzZXJ2aWNlcyBpdCBwcm92aWRlcy4gRm9yIERhdGFDaXRlIHRoaXMgbWVhbnMgdGhhdCB3ZSBzaG91bGQgdXNlIERPSXMgd2l0aCBhcHByb3ByaWF0ZSBtZXRhZGF0YSBhbmQgc3RyYXRlZ2llcyBmb3IgbG9uZy10ZXJtIHByZXNlcnZhdGlvbiBmb3IuLi48L2Rlc2NyaXB0aW9uPgogIDwvZGVzY3JpcHRpb25zPgo8L3Jlc291cmNlPgo=" }
  #
  #   subject { Metadata.create(xml: xml, doi: doi) }
  #
  #   it "creates xml" do
  #     expect(subject.xml).to eq(Base64.decode64(xml))
  #   end
  #
  #   it "creates namespace" do
  #     expect(subject.namespace).to eq("http://datacite.org/schema/kernel-4")
  #   end
  #
  #   it "valid model" do
  #     expect(subject.valid?).to be false
  #   end
  #
  #   it "validates xml" do
  #     expect(subject.errors[:xml]).to eq(["4:0: ERROR: Element '{http://datacite.org/schema/kernel-4}creators': Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator )."])
  #   end
  # end
end
