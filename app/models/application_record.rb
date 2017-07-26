class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  before_create :set_created_at
  before_save :set_updated_at

  def set_created_at
      self.created = DateTime.now.utc
  end

  def set_updated_at
    self.updated = DateTime.now.utc
  end
end
