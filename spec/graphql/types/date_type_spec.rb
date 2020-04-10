require "rails_helper"

describe DateType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:dateType).of_type("String") }
    it { is_expected.to have_field(:date).of_type("ISO8601DateTime!") }
  end
end
