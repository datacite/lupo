module Indexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    after_save { IndexerJob.perform_later(self, operation: "index") }
    after_destroy { IndexerJob.perform_later(self, operation: "delete") }
  end
end
