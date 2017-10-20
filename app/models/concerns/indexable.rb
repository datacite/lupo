module Indexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    after_save { IndexerJob.perform_later(self.id, operation: "index") }
    after_destroy { IndexerJob.perform_later(self.id, operation: "delete") }
  end

    def all
      query
    end

    def where(options={})
      query(options)
    end

end
