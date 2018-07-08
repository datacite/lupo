require 'rails_helper'

describe "Indexable", vcr: true do
  subject  { create(:client) }

  it 'send_message' do
    response = subject.send_message(subject.to_jsonapi)
    expect(response.message_id).to be_present
  end

  it 'send_import_message' do
    response = subject.send_import_message(subject.to_jsonapi)
    expect(response.message_id).to be_present
  end

  it 'send_delete_message' do
    response = subject.send_delete_message(subject.to_jsonapi)
    expect(response.message_id).to be_present
  end
end

describe "Indexable class methods", elasticsearch: true do
  context "client" do
    let!(:client) { create(:client) }

    it 'find_by_id' do
      sleep 1
      result = Client.find_by_id(client.symbol).results.first
      expect(result.symbol).to eq(client.symbol)
    end

    it 'find_by_ids' do
      sleep 1
      results = Client.find_by_ids(client.symbol).results
      expect(results.total).to eq(1)
    end

    it 'query' do
      sleep 1
      results = Client.query(client.name).results
      expect(results.total).to eq(1)
    end
  end

  context "provider" do
    let!(:provider) { create(:provider) }

    it 'find_by_id' do
      sleep 1
      result = Provider.find_by_id(provider.symbol).results.first
      expect(result.symbol).to eq(provider.symbol)
    end

    it 'find_by_ids' do
      sleep 1
      results = Provider.find_by_ids(provider.symbol).results
      expect(results.total).to eq(1)
    end

    it 'query' do
      sleep 1
      results = Provider.query(provider.name).results
      expect(results.total).to eq(1)
    end
  end

  context "doi" do
    let!(:doi) { create(:doi, title: "Soil investigations", publisher: "Pangaea", description: "this is a description") }

    it 'find_by_id' do
      sleep 1
      result = Doi.find_by_id(doi.doi).results.first
      expect(result.doi).to eq(doi.doi)
    end

    it 'query by doi' do
      sleep 1
      results = Doi.query(doi.doi).results
      expect(results.total).to eq(1)
    end

    # it 'query by title' do
    #   sleep 1
    #   results = Doi.query("soil").results
    #   expect(results.total).to eq(1)
    # end

    it 'query by publisher' do
      sleep 1
      results = Doi.query("pangaea").results
      expect(results.total).to eq(1)
    end

    # it 'query by description' do
    #   sleep 1
    #   results = Doi.query("description").results
    #   expect(results.total).to eq(1)
    # end

    it 'query by description not found' do
      sleep 1
      results = Doi.query("climate").results
      expect(results.total).to eq(0)
    end
  end

  context "prefix" do
    let!(:prefix) { create(:prefix) }

    it 'query' do
      sleep 1
      results = Prefix.query(prefix.prefix).results
      expect(results.total).to eq(1)
    end
  end
end
