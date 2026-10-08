# frozen_string_literal: true

require "rails_helper"

describe "Dois", type: :controller do
  subject { DataciteDoisController.new }

  it "no params" do
    params = ActionController::Parameters.new
    expect(subject.fields_from_params(params)).to be_nil
    expect(subject.fields_hash_from_params(params)).to be_nil
  end

  it "single value" do
    params = ActionController::Parameters.new(fields: { dois: "id" })
    expect(subject.fields_from_params(params)).to eq({ dois: ["id"] }.with_indifferent_access)
    expect(subject.fields_hash_from_params(params)).to eq({ dois: "id" }.with_indifferent_access)
  end

  it "multiple values" do
    params = ActionController::Parameters.new(fields: { dois: "id,subjects" })
    expect(subject.fields_from_params(params)).to eq({ dois: ["id", "subjects"] }.with_indifferent_access)
    expect(subject.fields_hash_from_params(params)).to eq({ dois: "id,subjects" }.with_indifferent_access)
  end
end
