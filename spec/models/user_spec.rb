require 'rails_helper'
require "cancan/matchers"

RSpec.describe User, type: :model do
  let(:new_user)  { FactoryGirl.attributes_for(:user) }
  subject { new_user }

  describe 'User attributes', :order => :defined do
    it "is valid with valid attributes" do
      user = User.new(subject)
      expect(user.name).to eq(new_user[:name])
    end
  end

  describe "abilities" do
    subject(:ability){ Ability.new(User.new(FactoryGirl.attributes_for(:user))) }
    let(:user){ {name: "kris" , uid: 11222, email: "kdskd@dsds", role: "member_user", jwt: "ds", orcid: "sds", member_id:"TIB", datacenter_id:"TIB.PANGAEA"} }

    context "when is a data centre admin" do
      let(:role){ "datacentre_admin" }

      it{ is_expected.not_to be_able_to(:create, Allocator.new) }
      it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacentre)) }
      it{ is_expected.not_to be_able_to(:update, Allocator.new) }
      it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
    end
    context "when is a data centre user" do
      let(:role){ "datacentre_user" }

      it{ is_expected.not_to be_able_to(:create, Allocator.new) }
      it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacentre)) }
      it{ is_expected.not_to be_able_to(:update, Allocator.new) }
      it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
    end
    context "when is a anonymous" do
      let(:role){ "anonymous" }

      it{ is_expected.not_to be_able_to(:read, Allocator.new) }
      it{ is_expected.to be_able_to(:read, Dataset.new) }
      it{ is_expected.not_to be_able_to(:update, Allocator.new) }
      it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
    end
    context "when is a member admin" do
      let(:role){ "member_admin" }

      it{ is_expected.not_to be_able_to(:create, Allocator.new) }
      it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacentre)) }
      it{ is_expected.not_to be_able_to(:update, Allocator.new) }
      it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
    end
    context "when is a member user" do
      let(:role){ "member_user" }

      it{ is_expected.not_to be_able_to(:create, Allocator.new) }
      it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacentre)) }
      it{ is_expected.not_to be_able_to(:update, Allocator.new) }
      it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
    end
    context "when is a staff admin" do
      let(:role){ "staff_admin" }

      it{ is_expected.not_to be_able_to(:create, Allocator.new) }
      it{ is_expected.to be_able_to(:read, FactoryGirl.create(:datacentre)) }
      it{ is_expected.not_to be_able_to(:update, Allocator.new) }
      it{ is_expected.not_to be_able_to(:destroy, Allocator.new) }
    end
  end
end





# subject { FactoryGirl.create(:claim) }
#
# it { is_expected.to validate_presence_of(:orcid) }
# it { is_expected.to validate_presence_of(:doi) }
# it { is_expected.to validate_presence_of(:source_id) }
# it { is_expected.to belong_to(:user) }
#
# describe 'collect_data', :order => :defined do
#   let(:user) { FactoryGirl.create(:valid_user) }
#   subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.21429") }
#
#   it 'no errors' do
#     response = subject.collect_data
#     expect(response.body["put_code"]).not_to be_blank
#     expect(response.status).to eq(201)
#   end
