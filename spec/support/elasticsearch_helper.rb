## https://github.com/elastic/elasticsearch-ruby/issues/462
SEARCHABLE_MODELS = [Client, Provider, Doi, DataciteDoi, OtherDoi, Event, Activity, Prefix, ClientPrefix, ProviderPrefix]

RSpec.configure do |config|
  config.around :all, elasticsearch: true do |example|
    SEARCHABLE_MODELS.each do |model|
      model.create_index
    end

    example.run

    SEARCHABLE_MODELS.each do |model|
      model.delete_index
    end
  end
end
