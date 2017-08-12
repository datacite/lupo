require 'rails_helper'

RSpec.describe Member, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:contact_email) }
  it { should validate_presence_of(:contact_name) }
  it { should validate_presence_of(:doi_quota_allowed) }
  it { should validate_presence_of(:doi_quota_used) }
  it { should validate_presence_of(:country_code) }
end
