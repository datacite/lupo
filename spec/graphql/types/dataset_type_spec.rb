require "rails_helper"

describe DatasetType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:datasets).of_type("DatasetDatasetConnectionWithMeta!") }
    it { is_expected.to have_field(:publications).of_type("DatasetPublicationConnectionWithMeta!") }
    it { is_expected.to have_field(:softwareSourceCodes).of_type("DatasetSoftwareConnectionWithMeta!") }
  end
end
