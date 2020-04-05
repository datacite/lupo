require "rails_helper"

describe IdentifierType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:identifierType).of_type("String") }
    it { is_expected.to have_field(:identifier).of_type("String") }
  end
end
