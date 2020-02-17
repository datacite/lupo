require "rails_helper"

describe DoiItem do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:creators).of_type("[Person!]") }
    it { is_expected.to have_field(:titles).of_type("[Title!]") }
    it { is_expected.to have_field(:publicationYear).of_type("Int") }
    it { is_expected.to have_field(:publisher).of_type("String") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
  end
end
