require "rails_helper"

describe Types::CountryType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:code).of_type("String") }
    it { is_expected.to have_field(:name).of_type("String") }
  end
end
