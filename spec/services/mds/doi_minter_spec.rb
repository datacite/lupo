# frozen_string_literal: true

require "rails_helper"

describe Mds::DoiMinter do
  subject(:minter) { described_class.new }

  describe "#resolve_doi_id" do
    it "rejects path DOI that does not match schema_org body identifier" do
      body = file_fixture("schema_org.json").read

      expect {
        minter.resolve_doi_id(
          "10.14454/other-doi",
          data: body,
          from: "schema_org",
        )
      }.to raise_error(IdentifierError, Mds::PATH_BODY_MISMATCH)
    end

    it "accepts matching path and schema_org body identifier" do
      body = file_fixture("schema_org.json").read
      # fixture DOI is 10.5438/4K3M-NYVG
      doi =
        minter.resolve_doi_id(
          "10.5438/4K3M-NYVG",
          data: body,
          from: "schema_org",
        )

      expect(doi).to eq("10.5438/4k3m-nyvg")
    end
  end
end
