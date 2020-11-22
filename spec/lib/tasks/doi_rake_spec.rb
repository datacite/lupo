# frozen_string_literal: true

require "rails_helper"

# describe "doi:create_index", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create_list(:doi, 10) }
#   let(:output) { "Created indexes dois-datacite-test_" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "doi:delete_index", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create_list(:doi, 10) }
#   let(:output) { "Deleted indexes dois-datacite-test_v1 and dois-datacite-test_v2.\n" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     Rake::Task["datacite_doi:create_index"].invoke
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "doi:delete_by_query", elasticsearch: true do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create(:doi, aasm_state: "findable") }
#   let(:output) { "0 DOIs with no URL found in the database.\n" }

#   before do
#     Doi.import
#     sleep 1
#   end

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     ENV['QUERY'] = "uid:#{doi.uid}"
#     ENV['INDEX'] = "dois-test"
#     expect(capture_stdout { subject.invoke }).to eq(output)
#   end
# end

describe "doi:set_url", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "0 DOIs with no URL found in the database.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:set_handle", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) do
    "0 DOIs found that are not registered in the Handle system.\n"
  end

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:set_minted", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "0 draft DOIs with URL found in the database.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:set_schema_version", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "[SetSchemaVersion] 0 Dois with [SetSchemaVersion].\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:set_registration_agency", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) do
    "[SetRegistrationAgency] 0 Dois with [SetRegistrationAgency].\n"
  end

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:set_license", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "[SetLicense] 0 Dois with [SetLicense].\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:set_language", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "[SetLanguage] 0 Dois with [SetLanguage].\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:set_identifiers", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "[SetIdentifiers] 0 Dois with [SetIdentifiers].\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:set_field_of_science", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "[SetFieldOfScience] 0 Dois with [SetFieldOfScience].\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:convert_affiliations", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "Queued converting 1 affiliations.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:convert_containers", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "Queued converting 1 containers.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:migrate_landing_page", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "Finished migrating landing pages.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:repair_landing_page", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let(:doi) do
    create(
      :doi,
      aasm_state: "findable",
      landing_page: {
        "checked" => Time.zone.now.utc.iso8601,
        "status" => 200,
        "url" => "https://example.org",
        "contentType" => "text/html",
        "error" => nil,
        "redirectCount" => 0,
        "redirectUrls" => [],
        "downloadLatency" => 200,
        "hasSchemaOrg" => true,
        "schemaOrgId" => "10.14454/10703",
        "dcIdentifier" => nil,
        "citationDoi" => nil,
        "bodyHasPid" => true,
      },
    )
  end
  let(:output) { "Updated landing page data for DOI #{doi.doi}\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    ENV["ID"] = doi.id.to_s
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end

describe "doi:delete_by_prefix", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi, aasm_state: "findable") }
  let(:output) { "" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end
