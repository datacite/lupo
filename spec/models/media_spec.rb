require 'rails_helper'

RSpec.describe Media, type: :model do
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:media_type) }
  it { should validates_numericality_of(:version) if :version? }
end
