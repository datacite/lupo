require 'rails_helper'


RSpec.describe Datacenter, type: :model  do
  # pending "add some examples to (or delete) #{__FILE__}"
  #
  # Association test
  # it { should have_many(:items).dependent(:destroy) }

  # Validation tests
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:allocator) }

end
