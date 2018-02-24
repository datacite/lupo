module Indexable
  extend ActiveSupport::Concern

  included do
    before_destroy { ElasticWorker.perform_async(data: self.to_jsonapi, action: "delete") }
    after_create { ElasticWorker.perform_async(data: self.to_jsonapi, action: "create") }
    after_update { ElasticWorker.perform_async(data: self.to_jsonapi, action: "update") }
  end
end
