require 'rails_helper'

describe Password do
  let!(:client) {create(:client)}
  let(:user) do
     {
        uid: "fasdsdasd3424234",
        name: "Kris",
        email: "sasa@sasa",
        provider_id: "",
        client_id: client.symbol,
        datacentre: 10012,
        role_id: "client_admin",
        iat: Time.now.to_i,
        exp: Time.now.to_i + 50 * 24 * 3600
      }
  end

  describe '#initialize' do
      it "has a valid factory" do
        expect(client).to be_valid
      end

      it 'can generate a password' do
      expect { Password.new(user, client) }.not_to raise_exception
    end

    it 'can pass a save password' do
      Password.new(user, client)
      oldpass = Client.where(symbol: client.symbol).first.password
      password = Password.new(user, client)
      newpass = Client.where(symbol: client.symbol).first.password

      expect(password.string).to be_truthy
      expect(oldpass).not_to eq(newpass)
    end
  end

  # describe '#url' do
  #   it 'can set and return the set url' do
  #     handle = Handler.new({id: 'myhandle'})
  #     handle.url = TEST_URL
  #     expect(handle.url).to eq(TEST_URL)
  #   end
  # end

end
