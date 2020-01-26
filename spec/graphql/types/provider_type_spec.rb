require "rails_helper"

describe ProviderType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:displayName).of_type("String") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:clients).of_type("ProviderClientConnectionWithMeta!") }
  end
end
