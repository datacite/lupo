require 'rails_helper'
require "cancan/matchers"

RSpec.describe User, type: :model do
  let(:user) { User.new(ENV['JWT_TOKEN']) }

  describe 'User attributes', :order => :defined do
    it "is valid with valid attributes" do
      expect(user.name).to eq("Josiah Carberry{n}")
    end
  end

  describe "abilities" do
    subject { Ability.new(user) }

    context "when is a data centre admin" do
      let(:role){ "datacenter_admin" }

      it{ is_expected.not_to be_able_to(:create, Member.new) }
      it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacenter)) }
      it{ is_expected.not_to be_able_to(:update, Member.new) }
      it{ is_expected.not_to be_able_to(:destroy, Member.new) }
    end
  #
  #   context "when is a data centre user" do
  #     let(:role){ "datacenter_user" }
  #
  #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacenter)) }
  #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
  #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
  #   end
  #
  #   context "when is a anonymous" do
  #     let(:role){ "anonymous" }
  #
  #     it{ is_expected.not_to be_able_to(:read, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, Dataset.new) }
  #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
  #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
  #   end
  #
  #   context "when is a member admin" do
  #     let(:role){ "member_admin" }
  #
  #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacenter)) }
  #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
  #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
  #   end
  #
  #   context "when is a member user" do
  #     let(:role) { "member_user" }
  #
  #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacenter)) }
  #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
  #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
  #   end
  #
  #   context "when is a staff admin" do
  #     let(:role) { "staff_admin" }
  #
  #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacenter)) }
  #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
  #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
  #   end
  end
end
