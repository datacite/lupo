# frozen_string_literal: true

require "rails_helper"

describe DefinedTermType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:termCode).of_type("String") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:inDefinedTermSet).of_type("String") }
  end
end
