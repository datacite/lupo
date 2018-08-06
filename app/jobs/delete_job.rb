class DeleteJob < ActiveJob::Base
  queue_as :lupo

  def perform(obj)
    obj.__elasticsearch__.delete_document
  end
end