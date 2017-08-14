module Indexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    before_create { self.created = Time.zone.now.utc }
    before_save { self.updated = Time.zone.now.utc }
    after_save { IndexerJob.perform_later(self, operation: "index") }
    after_destroy { IndexerJob.perform_later(self, operation: "delete") }
  end
end
