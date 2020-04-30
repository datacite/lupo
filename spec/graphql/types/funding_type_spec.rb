require "rails_helper"

describe FundingType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:funderName).of_type("String") }
    it { is_expected.to have_field(:funderIdentifier).of_type("String") }
    it { is_expected.to have_field(:funderIdentifierType).of_type("String") }
    it { is_expected.to have_field(:awardNumber).of_type("String") }
    it { is_expected.to have_field(:awardUri).of_type("String") }
    it { is_expected.to have_field(:awardTitle).of_type("String") }
  end
end
