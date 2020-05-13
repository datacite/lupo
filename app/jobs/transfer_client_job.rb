class TransferClientJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(client, options = {})
    symbol = client.symbol

    if client.present? && options[:target_id].present?
      options = {
        filter: { client_id: symbol.downcase },
        label: "[ClientTransfer]",
        job_name: "UpdateProviderIdJob",
        target_id: options[:target_id],
      }

      Doi.loop_through_dois(options)

      Rails.logger.info "[Transfer] DOIs updating has started for #{symbol} to #{options[:target_id]}."
    else
      Rails.logger.error "[Transfer] Error updating DOIs " + symbol + ": not found"
    end
  end
end
