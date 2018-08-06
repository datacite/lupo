class DeleteJob < ActiveJob::Base
  queue_as :lupo

  def perform(id, options={})
    begin
      Client.delete index: options[:class_name], type: options[:class_name].downcase, id: id
    rescue Elasticsearch::Transport::Transport::Errors::NotFound, ActiveJob::DeserializationError
      logger.debug "# not found, ID: #{record_id}"
    end
  end
end