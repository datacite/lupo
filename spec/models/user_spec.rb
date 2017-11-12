require 'rails_helper'

describe User, type: :model do
  let(:token) { User.generate_token }
  let(:user) { User.new(token) }

  describe 'User attributes', :order => :defined do
    it "ha name" do
      expect(user.name).to eq("Josiah Carberry")
    end
  end
end
