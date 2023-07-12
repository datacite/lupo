# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataDump, type: :model, elasticsearch: true do
  describe "Validations" do
    it { should validate_presence_of(:uid) }
    it { should validate_presence_of(:scope) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    # Temporarily disabled as these break with the other validators
    # Potentially adding a factory will resolve this?
    # Otherwise shift them to a separate second suite that _does_ create the object
    # it { should allow_value("metadata").for(:scope) }
    # it { should allow_value("link").for(:scope) }
    # it { should_not allow_value("invalid").for(:scope) }
  end
end
