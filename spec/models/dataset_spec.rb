require 'rails_helper'

RSpec.describe Dataset, type: :model do
  it { should validate_presence_of(:uid) }
  it { should validate_presence_of(:doi) }
  it { should validate_presence_of(:client_id) }
  it { should validate_presence_of(:url) }
end
