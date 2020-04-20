require 'rails_helper'

describe "Mailable", type: :model, vcr: true do
  let(:token) { User.generate_token }
  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, symbol: "DATACITE.DATACITE", name: "DataCite Repository", system_email: "test@datacite.org", provider: provider) }
  let(:title) { "DataCite Fabrica" }

  it "send_welcome_email" do
    response = client.send_welcome_email
    expect(response[:status]).to eq(200)
    expect(response[:message]).to eq("Queued. Thank you.")
  end

  # it "format_message_text" do
  #   template = "users/reset.text.erb"
  #   text = User.format_message_text(template: template, title: title, system_email: client.name, name: client.symbol, url: token)
  #   line = text.split("\n").first
  #   expect(line).to eq("Dear #{client.name},")
  # end

  # it "format_message_html" do
  #   template = "users/reset.html.erb"
  #   html = User.format_message_html(template: template, title: title, system_email: client.name, name: client.symbol, url: token)
  #   line = html.split("\n")[41]
  #   expect(line.strip).to eq("<h1 style=\"font-family: Arial, 'Helvetica Neue', Helvetica, sans-serif; box-sizing: border-box; margin-top: 0; color: #2F3133; font-size: 19px; font-weight: bold;\" align=\"left\">Dear #{client.name},</h1>")
  # end

  it "send message" do
    text = <<~BODY
      Dear #{client.name},

      Someone has requested a login link for the DataCite Fabrica '#{client.name}' account.

      You can change your password with the following link:

      TEST

      This link is valid for 48 hours.

      King regards,

      DataCite Support
    BODY
    subj = title + ": Password Reset Request"
    response = User.send_message(name: client.name, email: client.system_email, subject: subj, text: text)
    expect(response[:status]).to eq(200)
    expect(response[:message]).to eq("Queued. Thank you.")
  end

  context "send_notification_to_slack" do
    it "succeeds" do
      text =  "Using system email #{client.system_email}."
      options = { title: "TEST: new client account #{client.symbol} created." }
      expect(Client.send_notification_to_slack(text, options)).to eq("ok")
    end
  end
end
