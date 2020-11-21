require "rails_helper"

# describe "datacite_doi:create_index", order: :defined do
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

# describe "datacite_doi:delete_index", order: :defined do
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

# describe "datacite_doi:upgrade_index", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create_list(:doi, 10) }
#   let(:output) { "Upgraded inactive index dois-datacite-test" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     Rake::Task["datacite_doi:create_index"].invoke
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "datacite_doi:index_stats", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create_list(:doi, 10) }
#   let(:output) { "Active index dois-datacite-test" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     Rake::Task["datacite_doi:create_index"].invoke
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "datacite_doi:switch_index", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create_list(:doi, 10) }
#   let(:output) { "Switched active index to dois-datacite-test" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "datacite_doi:active_index", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create_list(:doi, 10) }
#   let(:output) { "dois-datacite-test_" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     Rake::Task["datacite_doi:create_index"].invoke
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "datacite_doi:monitor_reindex", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create_list(:doi, 10) }
#   let(:output) { "{}\n" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "datacite_doi:create_template", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create(:doi) }
#   let(:output) { "Updated template dois-datacite-test.\n" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "datacite_doi:delete_template", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create(:doi) }
#   let(:output) { "Deleted template dois-datacite-test.\n" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

# describe "datacite_doi:import", order: :defined do
#   include ActiveJob::TestHelper
#   include_context "rake"

#   let!(:doi)  { create_list(:doi, 10, aasm_state: "findable") }
#   let(:output) { "" }

#   it "prerequisites should include environment" do
#     expect(subject.prerequisites).to include("environment")
#   end

#   it "should run the rake task" do
#     expect(capture_stdout { subject.invoke }).to start_with(output)
#   end
# end

describe "datacite_doi:import_one", order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let(:doi) { create(:doi) }
  let(:output) { "[MySQL] Imported metadata for DOI #{doi.doi}.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    ENV["DOI"] = doi.doi
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end

describe "datacite_doi:index_one", order: :defined do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi) { create(:doi) }
  let(:output) { "Started indexing DOI #{doi.doi}.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    ENV["DOI"] = doi.doi
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end
