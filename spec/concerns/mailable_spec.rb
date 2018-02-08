require 'rails_helper'

describe "Mailable", type: :model, vcr: true do
  let(:token) { User.generate_token }
  let(:client) { create(:client, name: "DATACITE.DATACITE", contact_email: "support@datacite.org") }
  let(:title) { "DataCite DOI Fabrica" }

  it "format_message_text" do
    template = "users/reset.text.erb"
    text = User.format_message_text(template: template, title: title, contact_name: client.contact_name, name: client.symbol, url: token)
    line = text.split("\n").first
    expect(line).to eq("Dear #{client.contact_name},")
  end

  it "format_message_html" do
    template = "users/reset.html.erb"
    html = User.format_message_html(template: template, title: title, contact_name: client.contact_name, name: client.symbol, url: token)
    line = html.split("\n")[41]
    expect(line.strip).to eq("<h1 style=\"font-family: Arial, 'Helvetica Neue', Helvetica, sans-serif; box-sizing: border-box; margin-top: 0; color: #2F3133; font-size: 19px; font-weight: bold;\" align=\"left\">Dear #{client.contact_name},</h1>")
  end

  it "send message" do
    text = <<~BODY
      Dear #{client.contact_name},

      Someone has requested a login link for the DataCite DOI Fabrica '#{client.name}' account.

      You can change your password with the following link:

      TEST

      This link is valid for 48 hours.

      King regards,

      DataCite Support
    BODY
    subj = title + ": Password Reset Request"
    response = User.send_message(name: client.contact_name, email: client.contact_email, subject: subj, text: text)
    expect(response[:status]).to eq(200)
    expect(response[:message]).to eq("Queued. Thank you.")
  end
end
