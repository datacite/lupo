# frozen_string_literal: true

require "rails_helper"

describe Contact, type: :model do
  let(:contact) { create(:contact) }

  describe "Validations" do
    it { should validate_presence_of(:email) }
  end

  describe "Name" do
    it "concat names" do
      expect(contact.name).to eq("Josiah Carberry")
    end

    it "only given name" do
      contact = create(:contact, family_name: nil)
      expect(contact.name).to eq("Josiah")
    end

    it "only family name" do
      contact = create(:contact, given_name: nil)
      expect(contact.name).to eq("Carberry")
    end

    it "no names" do
      contact = create(:contact, given_name: nil, family_name: nil)
      expect(contact.name).to eq("")
    end
  end
end
