# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataDump, type: :model, elasticsearch: true do
  describe "Validations" do
    it { should validate_presence_of(:uid) }
    it { should validate_presence_of(:scope) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_inclusion_of(:scope).in_array(%w(metadata link)) }
    it { should allow_value("metadata").for(:scope).on(:create) }
    it { should allow_value("link").for(:scope).on(:create) }
    it { should_not allow_value("invalid").for(:scope).on(:create) }
  end
end
