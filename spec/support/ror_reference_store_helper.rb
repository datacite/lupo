# frozen_string_literal: true

# Prevents any spec that indexes DOIs (and thus triggers Rorable/RorReferenceStore)
# from hitting S3 when building funder_rors / funder_parent_rors.
# Specs that assert on specific ROR/funder behavior should include the shared
# context "ROR funding stubs for DOI indexing" to override with the expected mappings.
# Skip this stub in the RorReferenceStore spec so it can exercise the real store (with S3 stubbed).
RSpec.configure do |config|
  config.before(:each) do |example|
    next if example.metadata[:file_path]&.include?("spec/services/ror_reference_store_spec.rb")

    allow(RorReferenceStore).to receive(:funder_to_ror).and_return(nil)
    allow(RorReferenceStore).to receive(:ror_hierarchy).and_return(nil)
  end
end

# Shared context for examples that assert on specific funder_rors / funder_parent_rors
# (e.g. funded_by filter, "with funding references" in doi_spec).
# Overrides the default nil stubs with the mappings used by those examples.
RSpec.shared_context "ROR funding stubs for DOI indexing" do
  before do
    allow(RorReferenceStore).to receive(:funder_to_ror).with("501100000780").and_return("https://ror.org/00k4n6c32")
    allow(RorReferenceStore).to receive(:funder_to_ror).with("501100000781").and_return("https://ror.org/05mkt9r11")
    allow(RorReferenceStore).to receive(:ror_hierarchy).with("https://ror.org/00k4n6c32").and_return(
      { "ancestors" => ["https://ror.org/019w4f821"] }
    )
    allow(RorReferenceStore).to receive(:ror_hierarchy).with("https://ror.org/00a0jsq62").and_return(
      { "ancestors" => ["https://ror.org/04cw6st05"] }
    )
    allow(RorReferenceStore).to receive(:ror_hierarchy).with("https://ror.org/05mkt9r11").and_return(
      { "ancestors" => ["https://ror.org/00k4n6c32", "https://ror.org/019w4f821"] }
    )
    # Other arguments keep the default nil from the global before in this file
  end
end
