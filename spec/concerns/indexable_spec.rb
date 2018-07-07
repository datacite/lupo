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
  it 'find_by_id' do
    client = create(:client)
    response = Client.find_by_id(client.symbol)
    expect(response.results).to eq(2)
  end

  it 'find_by_ids' do
    client = create(:client)
    response = Client.find_by_ids(client.symbol)
    expect(response.results).to eq(2)
  end

  it 'query' do
    client = create(:client)
    puts client.name
    response = Client.query(client.name)
    expect(response.results).to eq(2)
  end
end
