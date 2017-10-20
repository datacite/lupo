
config = {
host: ENV['ES_HOST'],
transport_options: {
  request: { timeout: 5 }
}
}

if File.exists?("config/elasticsearch.yml")
  # config.merge!(YAML.load_file("config/elasticsearch.yml")[Rails.env].symbolize_keys)
  config.merge!(YAML.load_file("config/elasticsearch.yml").symbolize_keys)
end

# Elasticsearch::Model.client = Elasticsearch::Client.new(config)



Elasticsearch::Client.new url: ENV['ES_HOST'] do |f|
  f.request :aws_signers_v4,
            credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_ACCESS_KEY']),
            service_name: ENV['ES_NAME'],
            region: ENV['AWS_REGION']
end
