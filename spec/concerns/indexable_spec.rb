require 'rails_helper'

describe "Indexable", vcr: true do
  subject  { create(:client) }

  it 'send message' do
    message_body = { data: subject.to_jsonapi, action: "create" }
    response = subject.send_message(message_body)
    expect(response.message_id).to be_present
  end
end
