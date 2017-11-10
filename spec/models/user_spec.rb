# require 'rails_helper'
# require "cancan/matchers"
#
# describe User, type: :model do
#   let(:user) { User.new(ENV['JWT_TOKEN']) }
#
#   describe 'User attributes', :order => :defined do
#     it "is valid with valid attributes" do
#       expect(user.name).to eq("Josiah Carberry{n}")
#     end
#   end
#
#   describe "abilities" do
#     subject { Ability.new(user) }
#
#     context "when is a data centre admin" do
#       let(:role){ "client_admin" }
#
#       it{ is_expected.not_to be_able_to(:create, Provider.new) }
#       it{ is_expected.to be_able_to(:read, FactoryBot.create(:client)) }
#       it{ is_expected.not_to be_able_to(:update, Provider.new) }
#       it{ is_expected.not_to be_able_to(:destroy, Provider.new) }
#     end
#   #
#   #   context "when is a data centre user" do
#   #     let(:role){ "client_user" }
#   #
#   #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
#   #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:client)) }
#   #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
#   #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
#   #   end
#   #
#   #   context "when is a anonymous" do
#   #     let(:role){ "anonymous" }
#   #
#   #     it{ is_expected.not_to be_able_to(:read, Allocator.new) }
#   #     it{ is_expected.to be_able_to(:read, Dataset.new) }
#   #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
#   #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
#   #   end
#   #
#   #   context "when is a provider admin" do
#   #     let(:role){ "provider_admin" }
#   #
#   #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
#   #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:client)) }
#   #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
#   #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
#   #   end
#   #
#   #   context "when is a provider user" do
#   #     let(:role) { "provider_user" }
#   #
#   #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
#   #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:client)) }
#   #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
#   #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
#   #   end
#   #
#   #   context "when is a staff admin" do
#   #     let(:role) { "staff_admin" }
#   #
#   #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
#   #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:client)) }
#   #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
#   #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
#   #   end
#   end
# end
