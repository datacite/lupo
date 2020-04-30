require "rails_helper"

describe FacetType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("String") }
    it { is_expected.to have_field(:title).of_type("String") }
    it { is_expected.to have_field(:count).of_type("Int") }
  end
end
