require 'rails_helper'

describe "doi:import", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:doi)  { create_list(:doi, 10) }
  let(:output) { "" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end

  it "should enqueue an DoiImportByIdJob" do
    expect {
      capture_stdout { subject.invoke }
    }.to change(enqueued_jobs, :size).by(1)
    expect(enqueued_jobs.last[:job]).to be(DoiImportByIdJob)
  end
end
