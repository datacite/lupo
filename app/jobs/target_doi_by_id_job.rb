class TargetDoiByIdJob < ActiveJob::Base
  queue_as :lupo_background

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(id, options={})
    item = Event.where(uuid: id).first
    return false if item.blank?

    item.set_source_and_target_doi
    
    if item.save
      Rails.logger.info "Target doi for #{item.uuid} updated."
    else
      Rails.logger.error item.errors.inspect + " for #{item.uuid}"
    end
  end
end
