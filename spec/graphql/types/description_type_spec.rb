# frozen_string_literal: true

require "rails_helper"

describe DescriptionType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:descriptionType).of_type("String") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:lang).of_type("ID") }
  end
end
