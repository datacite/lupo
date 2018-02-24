class IndexJob < ActiveJob::Base
  queue_as :elastic
end
