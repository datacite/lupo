require "rails_helper"

describe FunderType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
    it { is_expected.to have_field(:viewCount).of_type("Int") }
    it { is_expected.to have_field(:downloadCount).of_type("Int") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnectionWithMeta") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnectionWithMeta") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnectionWithMeta") }
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithMeta") }
  end
end
