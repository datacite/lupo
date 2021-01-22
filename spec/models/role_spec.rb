# frozen_string_literal: true

require "rails_helper"

describe Role, type: :model do
  let(:role) { create(:role) }

  describe "Associations" do
    it "provider" do
      expect(role.provider.uid).to eq("Josiah Carberry")
    end

    it "contact" do
      expect(role.contact.uid).to eq("Josiah Carberry")
    end
  end
end
