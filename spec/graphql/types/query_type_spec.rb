require "rails_helper"

describe QueryType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:work).of_type("Work!") }
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal!") }
    it { is_expected.to have_field(:dataset).of_type("Dataset!") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal!") }
    it { is_expected.to have_field(:publication).of_type("Publication!") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnectionWithTotal!") }
    it { is_expected.to have_field(:software).of_type("Software!") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnectionWithTotal!") }
    it { is_expected.to have_field(:service).of_type("Service!") }
    it { is_expected.to have_field(:services).of_type("ServiceConnectionWithTotal!") }
    it { is_expected.to have_field(:audiovisual).of_type("Audiovisual!") }
    it { is_expected.to have_field(:audiovisuals).of_type("AudiovisualConnectionWithTotal!") }
    it { is_expected.to have_field(:collection).of_type("Collection!") }
    it { is_expected.to have_field(:collections).of_type("CollectionConnectionWithTotal!") }
    it { is_expected.to have_field(:data_paper).of_type("DataPaper!") }
    it { is_expected.to have_field(:data_papers).of_type("DataPaperConnectionWithTotal!") }
    it { is_expected.to have_field(:image).of_type("Image!") }
    it { is_expected.to have_field(:images).of_type("ImageConnectionWithTotal!") }
    it { is_expected.to have_field(:interactive_resource).of_type("InteractiveResource!") }
    it { is_expected.to have_field(:interactive_resources).of_type("InteractiveResourceConnectionWithTotal!") }
    it { is_expected.to have_field(:event).of_type("Event!") }
    it { is_expected.to have_field(:events).of_type("EventConnectionWithTotal!") }
    it { is_expected.to have_field(:model).of_type("Model!") }
    it { is_expected.to have_field(:models).of_type("ModelConnectionWithTotal!") }
    it { is_expected.to have_field(:physical_object).of_type("PhysicalObject!") }
    it { is_expected.to have_field(:physical_objects).of_type("PhysicalObjectConnectionWithTotal!") }
    it { is_expected.to have_field(:sound).of_type("Sound!") }
    it { is_expected.to have_field(:sounds).of_type("SoundConnectionWithTotal!") }
    it { is_expected.to have_field(:workflow).of_type("Workflow!") }
    it { is_expected.to have_field(:workflows).of_type("WorkflowConnectionWithTotal!") }
    it { is_expected.to have_field(:other).of_type("Other!") }
    it { is_expected.to have_field(:others).of_type("OtherConnectionWithTotal!") }

    it { is_expected.to have_field(:member).of_type("Member!") }
    it { is_expected.to have_field(:members).of_type("MemberConnectionWithTotal!") }
    it { is_expected.to have_field(:repository).of_type("Repository!") }
    it { is_expected.to have_field(:repositories).of_type("RepositoryConnectionWithTotal!") }
    it { is_expected.to have_field(:prefix).of_type("Prefix!") }
    it { is_expected.to have_field(:prefixes).of_type("PrefixConnectionWithTotal!") }
    it { is_expected.to have_field(:usage_report).of_type("UsageReport!") }
    it { is_expected.to have_field(:usage_reports).of_type("UsageReportConnectionWithTotal!") }

    it { is_expected.to have_field(:funder).of_type("Funder!") }
    it { is_expected.to have_field(:funders).of_type("FunderConnectionWithTotal!") }
    it { is_expected.to have_field(:data_catalog).of_type("DataCatalog!") }
    it { is_expected.to have_field(:data_catalogs).of_type("DataCatalogConnectionWithTotal!") }
    it { is_expected.to have_field(:organization).of_type("Organization!") }
    it { is_expected.to have_field(:organizations).of_type("OrganizationConnectionWithTotal!") }
    it { is_expected.to have_field(:person).of_type("Person!") }
    it { is_expected.to have_field(:people).of_type("PersonConnectionWithTotal!") }
  end
end
