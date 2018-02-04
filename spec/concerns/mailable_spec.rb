require 'rails_helper'

describe "Mailable", type: :model, vcr: true do
  let(:token) { User.generate_token }
  let(:client) { create(:client, name: "DATACITE.DATACITE", contact_email: "support@datacite.org") }
  let(:title) { "DataCite DOI Fabrica: Login Link Request" }

  it "sends message" do
    text = <<~BODY
      Dear #{client.contact_name},

      Someone has requested a login link for the DataCite DOI Fabrica '#{client.name}' account.
      
      You can change your password with the following link:

      TEST

      This link is valid for 48 hours.

      King regards,

      DataCite Support
    BODY
    response = User.send_message(name: client.contact_name, email: client.contact_email, subject: title, text: text)
    expect(response[:status]).to eq(200)
    expect(response[:message]).to eq("Queued. Thank you.")
  end
end
