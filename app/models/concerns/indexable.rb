module Indexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    if Rails.env.development? || Rails.env.stage?
      after_save { IndexerJob.perform_later(self, operation: "index") }
      after_destroy { IndexerJob.perform_later(self, operation: "delete") }
    end
  end
    #
    # def all
    #   query
    # end
    #
    # def where(options={})
    #   query(options)
    # end

end
