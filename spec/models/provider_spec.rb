require 'rails_helper'

RSpec.describe Provider, type: :model do
  describe "Validations" do
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:contact_email) }
    it { should validate_presence_of(:country_code) }
  end
end
