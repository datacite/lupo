require 'rails_helper'

describe OtherDoi, type: :model, vcr: true do
  it_behaves_like "an STI class"
end
