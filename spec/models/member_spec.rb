require 'rails_helper'

describe Member, type: :model, vcr: true do
  it "members" do
    members = Member.all[:data]
    expect(members.length).to eq(39)
    member = members.first
    expect(member.title).to eq("Australian National Data Service")
  end

  it "member" do
    member = Member.where(id: "ands")[:data]
    expect(member.title).to eq("Australian National Data Service")
  end
end
