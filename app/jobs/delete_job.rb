class DeleteJob < ActiveJob::Base
  queue_as :lupo

  def perform(id, options={})
    begin
      Client.delete index: options[:class_name].downcase + "s", type: options[:class_name].downcase, id: id
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      Rails.logger.debug "#{options[:class_name]} #{id} not found"
    end
  end
end