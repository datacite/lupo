require "rails_helper"

describe FunderType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:datasets).of_type("FunderDatasetConnectionWithMeta!") }
  end
end
