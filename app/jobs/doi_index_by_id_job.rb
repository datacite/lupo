class DoiIndexByIdJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(options={})
    Doi.index_by_id(options)
  end
end