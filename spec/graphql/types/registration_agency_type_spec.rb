require "rails_helper"

describe RegistrationAgencyType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID") }
    it { is_expected.to have_field(:name).of_type("String") }
  end
end
