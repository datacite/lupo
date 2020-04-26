require "rails_helper"

describe Types::QueryType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:work).of_type("Work!") }
    it { is_expected.to have_field(:works).of_type("WorkConnection!") }
    it { is_expected.to have_field(:dataset).of_type("Dataset!") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnection!") }
    it { is_expected.to have_field(:publication).of_type("Publication!") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnection!") }
    it { is_expected.to have_field(:software).of_type("Software!") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnection!") }
    it { is_expected.to have_field(:service).of_type("Service!") }
    it { is_expected.to have_field(:services).of_type("ServiceConnection!") }
    it { is_expected.to have_field(:audiovisual).of_type("Audiovisual!") }
    it { is_expected.to have_field(:audiovisuals).of_type("AudiovisualConnection!") }
    it { is_expected.to have_field(:collection).of_type("Collection!") }
    it { is_expected.to have_field(:collections).of_type("CollectionConnection!") }
    it { is_expected.to have_field(:data_paper).of_type("DataPaper!") }
    it { is_expected.to have_field(:data_papers).of_type("DataPaperConnection!") }
    it { is_expected.to have_field(:image).of_type("Image!") }
    it { is_expected.to have_field(:images).of_type("ImageConnection!") }
    it { is_expected.to have_field(:interactive_resource).of_type("InteractiveResource!") }
    it { is_expected.to have_field(:interactive_resources).of_type("InteractiveResourceConnection!") }
    it { is_expected.to have_field(:event).of_type("Event!") }
    it { is_expected.to have_field(:events).of_type("EventConnection!") }
    it { is_expected.to have_field(:model).of_type("Model!") }
    it { is_expected.to have_field(:models).of_type("ModelConnection!") }
    it { is_expected.to have_field(:physical_object).of_type("PhysicalObject!") }
    it { is_expected.to have_field(:physical_objects).of_type("PhysicalObjectConnection!") }
    it { is_expected.to have_field(:sound).of_type("Sound!") }
    it { is_expected.to have_field(:sounds).of_type("SoundConnection!") }
    it { is_expected.to have_field(:workflow).of_type("Workflow!") }
    it { is_expected.to have_field(:workflows).of_type("WorkflowConnection!") }
    it { is_expected.to have_field(:other).of_type("Other!") }
    it { is_expected.to have_field(:others).of_type("OtherConnection!") }

    it { is_expected.to have_field(:member).of_type("Member!") }
    it { is_expected.to have_field(:members).of_type("MemberConnection!") }
    it { is_expected.to have_field(:repository).of_type("Repository!") }
    it { is_expected.to have_field(:repositories).of_type("RepositoryConnection!") }
    it { is_expected.to have_field(:prefix).of_type("Prefix!") }
    it { is_expected.to have_field(:prefixes).of_type("PrefixConnection!") }
    it { is_expected.to have_field(:usage_report).of_type("UsageReport!") }
    it { is_expected.to have_field(:usage_reports).of_type("UsageReportConnection!") }

    it { is_expected.to have_field(:funder).of_type("Funder!") }
    it { is_expected.to have_field(:funders).of_type("FunderConnection!") }
    it { is_expected.to have_field(:data_catalog).of_type("DataCatalog!") }
    it { is_expected.to have_field(:data_catalogs).of_type("DataCatalogConnection!") }
    it { is_expected.to have_field(:organization).of_type("Organization!") }
    it { is_expected.to have_field(:organizations).of_type("OrganizationConnection!") }
    it { is_expected.to have_field(:person).of_type("Person!") }
    it { is_expected.to have_field(:people).of_type("PersonConnection!") }
  end
end
