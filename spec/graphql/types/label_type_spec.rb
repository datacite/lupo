# frozen_string_literal: true

require "rails_helper"

describe LabelType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:code).of_type("ID!") }
    it { is_expected.to have_field(:name).of_type("String") }
  end
end
