require "rails_helper"

describe Types::TitleType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:titleType).of_type("String") }
    it { is_expected.to have_field(:title).of_type("String") }
    it { is_expected.to have_field(:lang).of_type("ID") }
  end
end
