require 'rails_helper'

RSpec.describe Provider, type: :model do
  subject { create(:provider) }

  describe "password" do
    it "should not update the password" do
      subject = create(:provider)
      password = "Credible=Hangover8tighten"
      subject.update_attributes password: password
      expect(subject.password).to be_nil
    end

    it "should update the password when set_password is true" do
      subject = create(:provider, set_password: true)
      password = "Credible=Hangover8tighten"
      subject.update_attributes password: password
      expect(subject.password).to be_present
      expect(subject.password).not_to eq(password)
    end

    it "should not update the password when password is blank" do
      subject = create(:provider, set_password: true)
      password = ""
      subject.update_attributes password: password
      expect(subject.password).to be_nil
    end

    # API shows password as either "yes" or "not set"
    it "should not update the password when password is blank" do
      subject = create(:provider, set_password: true)
      password = "yes"
      subject.update_attributes password: password
      expect(subject.password).to be_nil
    end

    it "should not update the password when password is blank" do
      subject = create(:provider, set_password: true)
      password = "not set"
      subject.update_attributes password: password
      expect(subject.password).to be_nil
    end
  end

  describe "encrypt_password" do
    it "should encrypt the password" do
      password = "Credible=Hangover8tighten"
      encrypted_password = subject.encrypt_password(password)
      expect(encrypted_password).to be_present
      expect(subject.password).not_to eq(password)
    end
  end
end
