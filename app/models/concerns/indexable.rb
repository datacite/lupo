module Indexable
  extend ActiveSupport::Concern

  included do
    before_destroy { IndexJob.perform_later(self, operation: :delete) }
    after_create { IndexJob.perform_later(self, operation: :create) }
    after_update { IndexJob.perform_later(self, operation: :update) }
  end
end
