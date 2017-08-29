require 'rails_helper'

RSpec.describe Prefix, type: :model do
  it { should validate_presence_of(:uid) }
  it { should validate_presence_of(:prefix) }
end
