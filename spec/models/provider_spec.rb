require 'rails_helper'

RSpec.describe Provider, type: :model do
  it { should validate_presence_of(:uid) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:contact_email) }
  it { should validate_presence_of(:country_code) }
end
