module Indexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    unless Rails.env.production?
      after_save { IndexerJob.perform_later(self, operation: "index") }
      after_destroy { IndexerJob.perform_later(self, operation: "delete") }
    end
  end

    def all
      query
    end

    def where(options={})
      query(options)
    end

end
