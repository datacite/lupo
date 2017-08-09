class ApplicationRecord < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  include Searchable


  self.abstract_class = true
  before_create :set_created_at
  before_save :set_updated_at


  after_save    { Indexer.perform_async(:index,  self) }
  after_destroy { Indexer.perform_async(:delete, self) }

  def set_created_at
      self.created = DateTime.now.utc
  end

  def set_updated_at
    self.updated = DateTime.now.utc
  end
end
