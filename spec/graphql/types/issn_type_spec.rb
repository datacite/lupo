require "rails_helper"

describe Types::IssnType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:issnl).of_type("String") }
    it { is_expected.to have_field(:electronic).of_type("String") }
    it { is_expected.to have_field(:print).of_type("String") }
  end
end
