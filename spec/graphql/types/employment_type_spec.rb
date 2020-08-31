require "rails_helper"

describe EmploymentType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:organizationId).of_type("String") }
    it { is_expected.to have_field(:organizationName).of_type("String!") }
    it { is_expected.to have_field(:roleTitle).of_type("String") }
    it { is_expected.to have_field(:startDate).of_type("ISO8601DateTime") }
    it { is_expected.to have_field(:endDate).of_type("ISO8601DateTime") }
  end
end
