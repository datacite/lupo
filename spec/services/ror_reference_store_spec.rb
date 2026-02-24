# frozen_string_literal: true

require "rails_helper"

RSpec.describe RorReferenceStore, type: :service do
  let(:sample_json) { JSON.generate({ "100010552" => "https://ror.org/04ttjf776" }) }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:s3_response) { instance_double(Aws::S3::Types::GetObjectOutput, body: StringIO.new(sample_json)) }

  before do
    # Clear all ROR reference cache keys before each test
    RorReferenceStore::MAPPING_FILES.each_key do |key|
      meta = Rails.cache.read("ror_ref/#{key}/meta")
      if meta
        meta["chunks"].times { |i| Rails.cache.delete("ror_ref/#{key}/#{i}") }
      end
      Rails.cache.delete("ror_ref/#{key}/meta")
    end
  end

  describe "chunked cache write and read" do
    it "stores and retrieves data via chunked cache keys" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_return(s3_response)
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      result = described_class.funder_to_ror
      expect(result).to be_a(Hash)
      expect(result["100010552"]).to eq("https://ror.org/04ttjf776")

      # Meta key should now be populated
      meta = Rails.cache.read("ror_ref/funder_to_ror/meta")
      expect(meta).to be_a(Hash)
      expect(meta["chunks"]).to be >= 1
    end

    it "returns cached data on subsequent calls without hitting S3" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_return(s3_response).once
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      described_class.funder_to_ror
      result = described_class.funder_to_ror

      expect(result["100010552"]).to eq("https://ror.org/04ttjf776")
      expect(s3_client).to have_received(:get_object).once
    end
  end

  describe "partial cache miss recovery" do
    it "re-fetches from S3 when a chunk is missing" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_return(s3_response)
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      # Populate cache the first time
      described_class.funder_to_ror

      # Corrupt the cache by deleting chunk 0
      Rails.cache.delete("ror_ref/funder_to_ror/0")

      # Should trigger another S3 download
      result = described_class.funder_to_ror
      expect(result).to be_a(Hash)
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

      # Populate first
      described_class.funder_to_ror

      # Refresh
      described_class.refresh_all!

      result = described_class.funder_to_ror
      expect(result).to be_a(Hash)
    end
  end

  describe "S3 failure handling" do
    it "returns nil when S3 download fails" do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).and_raise(
        Aws::S3::Errors::ServiceError.new(nil, "Access Denied")
      )
      stub_const("ENV", ENV.to_h.merge("ROR_ANALYSIS_S3_BUCKET" => "test-bucket"))

      expect(described_class.funder_to_ror).to be_nil
    end
  end

  describe "cache key helpers" do
    it "uses expected meta cache key format" do
      expect(described_class.send(:meta_cache_key, :funder_to_ror)).to eq("ror_ref/funder_to_ror/meta")
    end

    it "uses expected chunk cache key format" do
      expect(described_class.send(:chunk_cache_key, :funder_to_ror, 0)).to eq("ror_ref/funder_to_ror/0")
      expect(described_class.send(:chunk_cache_key, :funder_to_ror, 2)).to eq("ror_ref/funder_to_ror/2")
    end
  end
end
