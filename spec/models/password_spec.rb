require 'rails_helper'

describe Password do
  let!(:client) {create(:client)}
  let(:user) do
     {
        uid: "fasdsdasd3424234",
        name: "Kris",
        email: "sasa@sasa",
        provider_id: "",
        client_id: "tib.pangaea",
        datacentre: 10012,
        role_id: "client_admin",
        iat: Time.now.to_i,
        exp: Time.now.to_i + 50 * 24 * 3600
      }
  end

  describe '#initialize' do
      it "has a valid factory" do
        client = Factory.create(:client)
        client.should be_valid
      end

      it 'can generate a password' do
      puts client.inspect
      expect { Password.new(user, client) }.not_to raise_exception
    end

    it 'can pass a save password' do
      password = Password.new(user, client)
      puts password.inspect
      expect(password).to eq("sdsds")
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
