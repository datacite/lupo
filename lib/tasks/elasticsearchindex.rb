# namespace :elasticsearch do
#   task build_client_index: :environment do
#     (1..Client.last.id).step(1000).each do |starting_index|
#       ElasticsearchBulkIndexWorker.perform_async('client', starting_index)
#     end
#   end
#
#   task build_member_index: :environment do
#     (1..Member.last.id).step(1000).each do |starting_index|
#       ElasticsearchBulkIndexWorker.perform_async('member', starting_index)
#     end
#   end
# end
