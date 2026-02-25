# frozen_string_literal: true

require "rails_helper"

RSpec.describe RorReferenceStore, type: :service do
  let(:sample_json) { JSON.generate({ "100010552" => "https://ror.org/04ttjf776" }) }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:s3_response) { instance_double(Aws::S3::Types::GetObjectOutput, body: StringIO.new(sample_json)) }

  before do
    # Clear all ROR reference cache keys before each test (per-key + populated sentinel)
    RorReferenceStore::MAPPING_FILES.each_key do |mapping|
      Rails.cache.delete("ror_ref/#{mapping}/#{RorReferenceStore::POPULATED_KEY_SUFFIX}")
      # Clear the value key used in funder_to_ror tests so cold-cache behavior is consistent
      Rails.cache.delete("ror_ref/#{mapping}/100010552")
    end
  end

  describe "per-key cache write and read" do
    it "stores and retrieves data via per-key cache entries" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_return(s3_response)
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      result = described_class.funder_to_ror("100010552")
      expect(result).to eq("https://ror.org/04ttjf776")

      expect(Rails.cache.read("ror_ref/funder_to_ror/populated")).to eq(true)
    end

    it "returns cached data on subsequent calls without hitting S3" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_return(s3_response).once
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      described_class.funder_to_ror("100010552")
      result = described_class.funder_to_ror("100010552")

      expect(result).to eq("https://ror.org/04ttjf776")
      expect(s3_client).to have_received(:get_object).once
    end
  end

  describe "cold cache refresh" do
    it "re-fetches from S3 when populated key is missing" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      # Two responses so the second get_object returns a fresh readable body (StringIO is consumed on read)
      allow(s3_client).to receive(:get_object).and_return(
        instance_double(Aws::S3::Types::GetObjectOutput, body: StringIO.new(sample_json)),
        instance_double(Aws::S3::Types::GetObjectOutput, body: StringIO.new(sample_json))
      )
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      described_class.funder_to_ror("100010552")

      # Simulate cold cache: remove populated sentinel and the value so lookup checks populated and refreshes
      Rails.cache.delete("ror_ref/funder_to_ror/populated")
      Rails.cache.delete("ror_ref/funder_to_ror/100010552")

      result = described_class.funder_to_ror("100010552")
      expect(result).to eq("https://ror.org/04ttjf776")
      expect(s3_client).to have_received(:get_object).twice
    end
  end

  describe "refresh_all!" do
    it "downloads all three mappings from S3" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_return(s3_response)
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      described_class.refresh_all!

      expect(s3_client).to have_received(:get_object).exactly(3).times
    end

    it "overwrites existing cache entries" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_return(s3_response)
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      described_class.funder_to_ror("100010552")
      described_class.refresh_all!

      result = described_class.funder_to_ror("100010552")
      expect(result).to eq("https://ror.org/04ttjf776")
    end
  end

  describe "S3 failure handling" do
    it "returns nil when S3 download fails and cache is cold" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_raise(
        Aws::S3::Errors::ServiceError.new(nil, "Access Denied")
      )
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      expect(described_class.funder_to_ror("100010552")).to be_nil
    end
  end

  describe "cache key helpers" do
    it "uses expected value cache key format" do
      expect(described_class.send(:value_cache_key, :funder_to_ror, "100010552")).to eq("ror_ref/funder_to_ror/100010552")
    end

    it "uses expected populated cache key format" do
      expect(described_class.send(:populated_cache_key, :funder_to_ror)).to eq("ror_ref/funder_to_ror/populated")
    end
  end
end
