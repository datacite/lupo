require 'rails_helper'

<<<<<<< HEAD
describe Metadata, type: :model do
  it { should validate_presence_of(:uid) }
  it { should validate_presence_of(:doi) }
  it { should validate_presence_of(:xml) }
  it { should validate_presence_of(:metadata_version) }
=======
RSpec.describe Metadata, type: :model do
  # it { should validate_presence_of(:dataset) }
  # it { should validate_presence_of(:metadata_version) }
>>>>>>> elasticsearch
end
