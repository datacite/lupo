require 'rails_helper'

<<<<<<< HEAD
describe Media, type: :model do
  it { should validate_presence_of(:uid) }
=======
RSpec.describe Media, type: :model do
>>>>>>> elasticsearch
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:media_type) }
end
