<<<<<<< HEAD
require 'rails_helper'
require "cancan/matchers"

describe User, type: :model do
  let(:user) { User.new(ENV['JWT_TOKEN']) }

  describe 'User attributes', :order => :defined do
    it "is valid with valid attributes" do
      expect(user.name).to eq("Josiah Carberry{n}")
    end
  end

  describe "abilities" do
    subject { Ability.new(user) }

    context "when is a data centre admin" do
      let(:role){ "client_admin" }

      it{ is_expected.not_to be_able_to(:create, Provider.new) }
      it{ is_expected.to be_able_to(:read, FactoryBot.create(:client)) }
      it{ is_expected.not_to be_able_to(:update, Provider.new) }
      it{ is_expected.not_to be_able_to(:destroy, Provider.new) }
    end
  #
  #   context "when is a data centre user" do
  #     let(:role){ "client_user" }
  #
  #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:client)) }
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
  #   context "when is a provider admin" do
  #     let(:role){ "provider_admin" }
  #
  #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:client)) }
  #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
  #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
  #   end
  #
  #   context "when is a provider user" do
  #     let(:role) { "provider_user" }
  #
  #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:client)) }
  #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
  #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
  #   end
  #
  #   context "when is a staff admin" do
  #     let(:role) { "staff_admin" }
  #
  #     it{ is_expected.not_to be_able_to(:create, Allocator.new) }
  #     it{ is_expected.to be_able_to(:read, FactoryGirl.create(:client)) }
  #     it{ is_expected.not_to be_able_to(:update, Allocator.new) }
  #     it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
  #   end
  end
end
=======
# require 'rails_helper'
# require "cancan/matchers"
#
# RSpec.describe User, type: :model do
#   let!(:provider) { create(:provider) }
#   let!(:client) { create(:client, provider_id: provider.symbol) }
#
#
#   describe "User" do
#     describe "abilities" do
#       let(:user) { User.new(ENV['JWT_TOKEN']) }
#       subject(:ability){ Ability.new(user) }
#
#       context "when is an account manager" do
#
#
#         it{
#
#           user.role_id = "provider_admin"
#           user.provider_id = provider.symbol
#           Ability.new(user)
#
#           is_expected.to be_able_to(:update, Client.new)
#
#         }
#       end
#     end
#   end
#
#   # describe 'User attributes', :order => :defined do
#   #   it "is valid with valid attributes" do
#   #     expect(user.name).to eq("Josiah Carberry{n}")
#   #   end
#   # end
#   #
#   # describe "abilities" do
#   #   subject(:ability){ Ability.new(user) }
#   #
#   #   context "when is a data centre admin" do
#   #     let(:role_id){ "client_admin" }
#   #
#   #     it{
#   #       puts ability.inspect
#   #       is_expected.not_to be_able_to(:create, Provider.new) }
#   #     it{ is_expected.to be_able_to(:read, create(:client)) }
#   #     it{ is_expected.not_to be_able_to(:update, Provider.new) }
#   #     it{ is_expected.not_to be_able_to(:destroy, Provider.new) }
#   #   end
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
#   # end
# end
>>>>>>> elasticsearch
