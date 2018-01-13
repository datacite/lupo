require 'rails_helper'

describe Provider, type: :model do
  subject { create(:provider) }

  describe "encrypt_password_sha256" do
    it "should encrypt the password" do
      password = "Credible=Hangover8tighten"
      encrypted_password = subject.encrypt_password_sha256(password)
      expect(encrypted_password).to be_present
      expect(subject.password).not_to eq(password)
    end
  end
end
