# frozen_string_literal: true

require "rails_helper"

RSpec.describe SharedContainerSettings, type: :service do
  # Define a constant for the cache key to avoid repeating the "magic string"
  let(:cache_key) { SharedContainerSettings::INDEX_SYNC_KEY }

  # Clear only the specific cache key before and after each test
  # This ensures test isolation without affecting other cached data
  before do
    Rails.cache.delete(cache_key)
    SharedContainerSettings::INDEX_SYNC_MODELS.each do |model_name|
      allow(model_name.constantize).to receive(:refresh_index_name_cache!)
    end
  end

  after do
    Rails.cache.delete(cache_key)
  end

  describe ".index_sync_enabled?" do
    context "when the cache is set to true" do
      it "returns true" do
        Rails.cache.write(cache_key, true)
        expect(described_class.index_sync_enabled?).to be(true)
      end
    end

    context "when the cache is set to false" do
      it "returns false" do
        Rails.cache.write(cache_key, false)
        expect(described_class.index_sync_enabled?).to be(false)
      end
    end

    context "when the cache key is not set (nil)" do
      it "returns false" do
        # We don't write anything to the cache, so it's nil
        expect(described_class.index_sync_enabled?).to be(false)
      end
    end

    context 'when the cache contains a non-boolean "truthy" value' do
      it "returns false because it performs a strict boolean check" do
        # This test ensures that we aren't accidentally treating strings
        # or numbers as true.
        Rails.cache.write(cache_key, "true")
        expect(described_class.index_sync_enabled?).to be(false)
      end
    end
  end

  describe ".enable_index_sync!" do
    it "writes `true` to the cache" do
      # We don't care about the return value, we care about the side effect.
      described_class.enable_index_sync!
      expect(Rails.cache.read(cache_key)).to be(true)
    end

    it "changes the value from false to true" do
      Rails.cache.write(cache_key, false)

      # The `change` matcher is a great way to test side effects.
      # It checks the value of the block before and after the code runs.
      expect {
        described_class.enable_index_sync!
      }.to change { Rails.cache.read(cache_key) }.from(false).to(true)
    end

    it "warms index name caches for DOI models" do
      described_class.enable_index_sync!

      SharedContainerSettings::INDEX_SYNC_MODELS.each do |model_name|
        expect(model_name.constantize).to have_received(:refresh_index_name_cache!)
      end
    end

    it "still enables sync when warming a model cache fails" do
      allow(DataciteDoi).to receive(:refresh_index_name_cache!).and_raise(
        Elastic::Transport::Transport::Errors::TooManyRequests.new("rate limited"),
      )

      described_class.enable_index_sync!

      expect(Rails.cache.read(cache_key)).to be(true)
    end
  end

  describe ".disable_index_sync!" do
    it "writes `false` to the cache" do
      described_class.disable_index_sync!
      expect(Rails.cache.read(cache_key)).to be(false)
    end

    it "changes the value from true to false" do
      Rails.cache.write(cache_key, true)

      expect {
        described_class.disable_index_sync!
      }.to change { Rails.cache.read(cache_key) }.from(true).to(false)
    end

    it "does not refresh index name caches" do
      described_class.disable_index_sync!

      SharedContainerSettings::INDEX_SYNC_MODELS.each do |model_name|
        expect(model_name.constantize).not_to have_received(:refresh_index_name_cache!)
      end
    end
  end
end
