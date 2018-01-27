require 'rails_helper'

describe Provider, type: :model do
  subject { create(:provider) }

  describe "encrypt_password_sha256" do
    it "should encrypt the password" do
      password_input = "Credible=Hangover8tighten"
      password = subject.encrypt_password_sha256(password_input)
      subject.password_input = password_input
      expect(subject.password).to eq(password)
    end
  end
end
