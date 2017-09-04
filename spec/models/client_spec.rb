require 'rails_helper'

RSpec.describe Client, type: :model do
  it { should validate_presence_of(:uid) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:contact_email) }
end
