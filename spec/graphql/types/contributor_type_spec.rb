# frozen_string_literal: true

require "rails_helper"

describe ContributorType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:contributorType).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:givenName).of_type("String") }
    it { is_expected.to have_field(:familyName).of_type("String") }
    it { is_expected.to have_field(:affiliation).of_type("[Affiliation!]") }
  end
end
