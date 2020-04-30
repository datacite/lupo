require "rails_helper"

describe AddressType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:type).of_type("String") }
    it { is_expected.to have_field(:streetAddress).of_type("String") }
    it { is_expected.to have_field(:postalCode).of_type("String") }
    it { is_expected.to have_field(:locality).of_type("String") }
    it { is_expected.to have_field(:region).of_type("String") }
    it { is_expected.to have_field(:country).of_type("String") }
  end
end
