class ElasticWorker
  include Shoryuken::Worker

  shoryuken_options queue: ->{ "#{ENV['RAILS_ENV']}_elastic" }
end
