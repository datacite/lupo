require 'rails_helper'

describe Media, type: :model do
  it { should validate_presence_of(:uid) }
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:dataset_id) }
  it { should validate_presence_of(:media_type) }
  it { should validates_numericality_of(:version) if :version? }
end
