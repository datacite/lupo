# frozen_string_literal: true

require "rails_helper"

describe "ParamsSanitizer", type: :concern do
## test all instance methods
  describe "instance methods" do
    let(:params) { { "xml" => nil } }
    subject { ParamsSanitizer.new(params) }

    context "responds to its methods" do
      it { expect(subject).to respond_to(:cleanse) }
    end
  end


  describe "add_xml" do
    context "when xml is nil" do
      let(:params) { { "xml" => nil } }
      subject { ParamsSanitizer.new(params) }

      it "should return nil" do
        expect(subject.add_xml).to eq(nil)
      end
    end

    context "when xml is empty" do
      let(:params) { { "xml" => "" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        expect(subject.add_xml).to eq(nil)
      end
    end

    context "when xml is not string" do
      let(:params) { { "xml" => 123 } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        expect(subject.add_xml).to eq(nil)
      end
    end

    context "when xml is string" do
      let(:params) { { "xml" => "<xml></xml>" } }
      subject { ParamsSanitizer.new(params) }
      it "should return hash" do
        expect(subject.add_xml).to eq(nil)
      end
    end
  end

  describe "add_metadata_version" do
    context "when params is nil" do
      let(:params) { { "version_info" => nil } }
      subject { ParamsSanitizer.new(params) }

      it "should return nil" do
        subject.add_metadata_version(params)
        expect(subject.get_params[:version_info]).to eq(nil)
      end
    end

    context "when params is empty" do
      let(:params) { { "version_info" => "" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_metadata_version(params)
        expect(subject.get_params[:version_info]).to eq(nil)
      end
    end

    context "when params is not hash" do
      let(:params) { { "version_info" => 123 } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_metadata_version(params)
        expect(subject.get_params[:version_info]).equal?(123)
      end
    end
  end


  describe "add_random_id" do
    context "when params is nil" do
      let(:params) { { "prefix" => nil, "doi" => nil } }
      subject { ParamsSanitizer.new(params) }

      it "should return nil" do
        subject.add_random_id
        expect(subject.get_params[:doi]).to eq(nil)
      end
    end

    context "when params is empty" do
      let(:params) { { "prefix" => "", "doi" => "" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_random_id
        expect(subject.get_params[:doi]).to eq(nil)
      end
    end

    context "when params is not hash" do
      let(:params) { { "prefix" => 123, "doi" => 123 } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_random_id
        expect(subject.get_params[:doi]).to eq(nil)
      end
    end

    context "when params is hash" do
      subject { ParamsSanitizer.new({ prefix: "10.1233", doi: "" }) }

      it "adds correctly random doi" do
        subject.add_random_id()
        expect(subject.get_params[:doi]).to start_with("10.1233")
      end
    end
  end


  describe "add_schema_version" do
    context "when params is nil" do
      let(:params) { { "schemaVersion" => nil } }
      subject { ParamsSanitizer.new(params) }

      it "should return nil" do
        subject.add_schema_version(params)
        expect(subject.get_params[:schemaVersion]).to eq(nil)
      end
    end

    context "when params is empty" do
      let(:params) { { "schemaVersion" => "" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_schema_version(params)
        expect(subject.get_params[:schemaVersion]).to eq(nil)
      end
    end

    context "when params is not hash" do
      let(:params) { { "schemaVersion" => 123 } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_schema_version(params)
        expect(subject.get_params[:schemaVersion]).equal?(123)
      end
    end

    context "when params is hash" do
      subject { ParamsSanitizer.new({ schemaVersion: "3.1" }) }

      it "add schema version correctly" do
        subject.add_schema_version({ from: "datacite" })
        expect(subject.get_params[:schemaVersion]).equal?("3")
      end
    end
  end
end
