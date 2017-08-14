require 'sidekiq/api'

class Status
  extend ActiveModel::Naming
  include ActiveModel::Serialization

  attr_reader :id, :state, :jobs

  def initialize
    @id = "status"
    @state = current_status
    @jobs = jobs
  end

  def jobs
    { processed: stats.processed,
      failed: stats.failed,
      busy: stats.workers_size,
      enqueued: stats.enqueued,
      retries: stats.retry_size,
      scheduled: stats.scheduled_size,
      dead: stats.dead_size }
  end

  def stats
    @stats ||= ::Sidekiq::Stats.new
  end

  def process_set
    @process_set ||= Sidekiq::ProcessSet.new
  end

  def current_status
    if stats.workers_size > 0
      "working"
    elsif process_set.size > 0
      "waiting"
    else
      "stopped"
    end
  end
end
