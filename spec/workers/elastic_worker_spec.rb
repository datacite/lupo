require 'rails_helper'

describe ElasticWorker, vcr: true do
  let(:provider)  { create(:provider) }
  let(:client)  { create(:client, provider: provider) }

  subject { ElasticWorker }

  it 'perform_async' do
    response = subject.perform_async(data: client.to_jsonapi, action: "create")
    puts response
    expect(response.message_id).to be_present
  end
end
