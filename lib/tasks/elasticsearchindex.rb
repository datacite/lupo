# namespace :elasticsearch do
#   task build_datacenter_index: :environment do
#     (1..Datacenter.last.id).step(1000).each do |starting_index|
#       ElasticsearchBulkIndexWorker.perform_async('datacenter', starting_index)
#     end
#   end
#
#   task build_member_index: :environment do
#     (1..Member.last.id).step(1000).each do |starting_index|
#       ElasticsearchBulkIndexWorker.perform_async('member', starting_index)
#     end
#   end
# end
