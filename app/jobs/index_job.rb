class IndexJob < ActiveJob::Base
  queue_as :lupo

  def perform(obj)
    obj.__elasticsearch__.index_document
  end
end