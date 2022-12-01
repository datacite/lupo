# frozen_string_literal: true

require "rails_helper"

describe "MetadataSanitizer", type: :controller do
  subject { MetadataSanitizer.new({}) }

  describe "add_xml" do
    it "it extract correctly" do
      subject.add_xml
      expect(subject.get_params).equal?(nil)
    end
  end

  describe "add_metadata_version" do
    it "adds correctly using meta" do
      subject.add_metadata_version({ "version_info": 3 })
      expect(subject.get_params[:version_info]).equal?(3)
    end
  end

  describe "add_random_id" do
    subject { MetadataSanitizer.new({ prefix: "10.1233", doi: "" }) }

    it "adds correctly random doi" do
      subject.add_random_id()
      expect(subject.get_params[:doi]).to start_with("10.1233")
    end
  end

  describe "add_schema_version" do
    subject { MetadataSanitizer.new({ schemaVersion: "3.1" }) }

    it "add schema version correctly" do
      subject.add_schema_version({ from: "datacite" })
      expect(subject.get_params[:schemaVersion]).equal?("3")
    end
  end
end