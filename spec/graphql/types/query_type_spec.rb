# frozen_string_literal: true

require "rails_helper"

describe QueryType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:work).of_type("Work!") }
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal!") }
    it { is_expected.to have_field(:dataset).of_type("Dataset!") }
    it do
      is_expected.to have_field(:datasets).of_type(
        "DatasetConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:publication).of_type("Publication!") }
    it do
      is_expected.to have_field(:publications).of_type(
        "PublicationConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:software).of_type("Software!") }
    it do
      is_expected.to have_field(:softwares).of_type(
        "SoftwareConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:service).of_type("Service!") }
    it do
      is_expected.to have_field(:services).of_type(
        "ServiceConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:audiovisual).of_type("Audiovisual!") }
    it do
      is_expected.to have_field(:audiovisuals).of_type(
        "AudiovisualConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:collection).of_type("Collection!") }
    it do
      is_expected.to have_field(:collections).of_type(
        "CollectionConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:data_paper).of_type("DataPaper!") }
    it do
      is_expected.to have_field(:data_papers).of_type(
        "DataPaperConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:image).of_type("Image!") }
    it do
      is_expected.to have_field(:images).of_type("ImageConnectionWithTotal!")
    end
    it do
      is_expected.to have_field(:interactive_resource).of_type(
        "InteractiveResource!",
      )
    end
    it do
      is_expected.to have_field(:interactive_resources).of_type(
        "InteractiveResourceConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:event).of_type("Event!") }
    it do
      is_expected.to have_field(:events).of_type("EventConnectionWithTotal!")
    end
    it { is_expected.to have_field(:model).of_type("Model!") }
    it do
      is_expected.to have_field(:models).of_type("ModelConnectionWithTotal!")
    end
    it do
      is_expected.to have_field(:physical_object).of_type("PhysicalObject!")
    end
    it do
      is_expected.to have_field(:physical_objects).of_type(
        "PhysicalObjectConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:sound).of_type("Sound!") }
    it do
      is_expected.to have_field(:sounds).of_type("SoundConnectionWithTotal!")
    end
    it { is_expected.to have_field(:workflow).of_type("Workflow!") }
    it do
      is_expected.to have_field(:workflows).of_type(
        "WorkflowConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:other).of_type("Other!") }
    it do
      is_expected.to have_field(:others).of_type("OtherConnectionWithTotal!")
    end

    it { is_expected.to have_field(:member).of_type("Member!") }
    it do
      is_expected.to have_field(:members).of_type("MemberConnectionWithTotal!")
    end
    it { is_expected.to have_field(:repository).of_type("Repository!") }
    it do
      is_expected.to have_field(:repositories).of_type(
        "RepositoryConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:prefix).of_type("Prefix!") }
    it do
      is_expected.to have_field(:prefixes).of_type("PrefixConnectionWithTotal!")
    end
    it { is_expected.to have_field(:usage_report).of_type("UsageReport!") }
    it do
      is_expected.to have_field(:usage_reports).of_type(
        "UsageReportConnectionWithTotal!",
      )
    end

    it { is_expected.to have_field(:funder).of_type("Funder!") }
    it do
      is_expected.to have_field(:funders).of_type("FunderConnectionWithTotal!")
    end
    it { is_expected.to have_field(:data_catalog).of_type("DataCatalog!") }
    it do
      is_expected.to have_field(:data_catalogs).of_type(
        "DataCatalogConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:organization).of_type("Organization!") }
    it do
      is_expected.to have_field(:organizations).of_type(
        "OrganizationConnectionWithTotal!",
      )
    end
    it { is_expected.to have_field(:person).of_type("Person!") }
    it do
      is_expected.to have_field(:people).of_type("PersonConnectionWithTotal!")
    end
  end
end
