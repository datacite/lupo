class TransferClientJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(symbol, options = {})
    client = Client.where(symbol: symbol).first

    if client.present? && options[:target_id].present?
      options = {
        from_id: Doi.minimum(:id).to_i,
        until_id: Doi.maximum(:id).to_i,
        filter: { client_id: symbol.downcase },
        label: "[ClientTransfer]",
        job_name: "UpdateProviderIdJob",
        target_id: options[:target_id],
      }

      Doi.loop_through_dois(options)

      Rails.logger.info "[Transfer] DOIs transfer has started for #{client.symbol} to #{options[:target_id]}."
    else
      Rails.logger.error "[Transfer] Error transferring DOIs " + symbol + ": not found"
    end
  end
end
