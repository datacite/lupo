module Indexable
    extend ActiveSupport::Concern
  
    included do

      after_save    {ElasticsearchJob.perform_later( self.to_jsonapi, "index")}

      after_destroy {ElasticsearchJob.perform_later( self.to_jsonapi, "delete")}

    end
  end