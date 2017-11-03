require 'rails_helper'

describe Prefix, type: :model do
  it { should validate_presence_of(:prefix) }
end
