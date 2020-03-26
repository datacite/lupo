require "rails_helper"

describe PersonType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:givenName).of_type("String") }
    it { is_expected.to have_field(:familyName).of_type("String") }
    it { is_expected.to have_field(:datasets).of_type("[Dataset!]") }
    it { is_expected.to have_field(:publications).of_type("[Publication!]") }
    it { is_expected.to have_field(:softwares).of_type("[Software!]") }
  end
end
