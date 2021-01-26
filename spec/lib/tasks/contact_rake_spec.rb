# frozen_string_literal: true

require "rails_helper"

describe "contact:import_from_providers", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:provider) { create(:provider) }
  let(:output) { "Imported voting contact robin@example.com for provider #{provider.symbol}.\nImported billing contact trisha@example.com for provider #{provider.symbol}." }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to start_with(output)
  end
end
