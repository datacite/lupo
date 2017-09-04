# namespace :elasticsearch do
#   task build_client_index: :environment do
#     (1..Client.last.id).step(1000).each do |starting_index|
#       ElasticsearchBulkIndexWorker.perform_async('client', starting_index)
#     end
#   end
#
#   task build_provider_index: :environment do
#     (1..Provider.last.id).step(1000).each do |starting_index|
#       ElasticsearchBulkIndexWorker.perform_async('provider', starting_index)
#     end
#   end
# end
