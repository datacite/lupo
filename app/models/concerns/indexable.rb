module Indexable
    extend ActiveSupport::Concern
  
    included do
      after_save    {ElasticsearchJob.perform_later( self.to_jsonapi)}
    end
end