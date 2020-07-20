class LoopThroughDoisJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids, options={})
    ids.each do |id|
      Object.const_get(options[:job_name]).perform_later(id, options)
      sleep 0.1
    end
  end
end
