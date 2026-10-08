# frozen_string_literal: true

require "rails_helper"

describe BinaryActiveFlag do
  # Provider includes BinaryActiveFlag; exercise the private helpers via send.
  let(:provider) { build(:provider) }

  describe "#binary_is_active?" do
    it "treats true-like values as active" do
      expect(provider.send(:binary_is_active?, true)).to be true
      expect(provider.send(:binary_is_active?, 1)).to be true
      expect(provider.send(:binary_is_active?, "1")).to be true
      expect(provider.send(:binary_is_active?, "\x01")).to be true
    end

    it "treats false-like values as inactive" do
      expect(provider.send(:binary_is_active?, false)).to be false
      expect(provider.send(:binary_is_active?, 0)).to be false
      expect(provider.send(:binary_is_active?, "0")).to be false
      expect(provider.send(:binary_is_active?, nil)).to be false
      expect(provider.send(:binary_is_active?, "")).to be false
      expect(provider.send(:binary_is_active?, "\x00")).to be false
    end

    # Regression for product-backlog#912: "\x00" is truthy in Ruby but means inactive.
    it "does not treat the inactive binary flag as active" do
      expect(!!"\x00").to be true
      expect(provider.send(:binary_is_active?, "\x00")).to be false
    end
  end

  describe "#normalize_binary_is_active" do
    it "writes binary flags for active and inactive states" do
      provider.is_active = false
      provider.send(:normalize_binary_is_active)
      expect(provider.is_active).to eq("\x00")

      provider.is_active = "\x00"
      provider.send(:normalize_binary_is_active)
      expect(provider.is_active).to eq("\x00")

      provider.is_active = true
      provider.send(:normalize_binary_is_active)
      expect(provider.is_active).to eq("\x01")
    end
  end
end
