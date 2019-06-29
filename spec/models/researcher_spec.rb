# frozen_string_literal: true

require "rails_helper"

describe Researcher, type: :model, vcr: true do
  it { is_expected.to validate_presence_of(:uid) }
  it { is_expected.to validate_uniqueness_of(:uid) }
end
