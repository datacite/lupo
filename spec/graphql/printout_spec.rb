require "rails_helper"

describe LupoSchema do
  it "printout is up-to-date" do
    current_defn = LupoSchema.to_definition
    printout_defn = File.read(Rails.root.join("app/graphql/schema.graphql"))
    expect(current_defn).to eq(printout_defn)
  end
end
