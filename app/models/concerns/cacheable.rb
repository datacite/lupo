module Cacheable
  extend ActiveSupport::Concern

  included do
    def cached_client_response(id, options={})
      Rails.cache.fetch("client_response/#{id}", expires_in: 7.days) do
        Client.where(symbol: id).select(:id, :symbol, :name, :created).first
      end
    end

    def cached_prefix_response(prefix, options={})
      Rails.cache.fetch("prefix_response/#{prefix}", expires_in: 7.days) do
        Prefix.where(prefix: prefix).select(:id, :prefix, :created).first
      end
    end

    def cached_providers
      Rails.cache.fetch("providers", expires_in: 1.day) do
        Provider.all.select(:id, :symbol, :name, :created)
      end
    end

    def cached_provider_response(symbol, options={})
      Rails.cache.fetch("provider_response/#{symbol}", expires_in: 7.days) do
        Provider.where(symbol: symbol).select(:id, :symbol, :name, :created).first
      end
    end

    def cached_allocator_response(symbol, options={})
      Rails.cache.fetch("provider_response/#{symbol}", expires_in: 7.days) do
        Provider.where(id: allocator).select(:id, :symbol, :name, :created).first
      end
    end

    def cached_provider_response_by_id(id, options={})
      Rails.cache.fetch("provider_response/#{id}", expires_in: 7.days) do
        Provider.where(id: id).select(:id, :symbol, :name, :created).first
      end
    end
  end

  module ClassMethods
    def cached_providers
      Rails.cache.fetch("providers", expires_in: 1.day) do
        Provider.all.select(:id, :symbol, :name, :created)
      end
    end

    def cached_resource_types
      Rails.cache.fetch("resource_types", expires_in: 1.day) do
        ResourceType.all[:data]
      end
    end

    def cached_datasets
      Rails.cache.fetch("datasets", expires_in: 1.day) do
        Dataset.all
      end
    end

    def cached_datasets_options(options={})
      Rails.cache.fetch("records_datasets", :expires_in => 1.day) do
        collection = cached_datasets
        # collection = collection.all unless options.values.include?([nil,nil])
        collection = collection.where('extract(year  from created) = ?', options[:year]) if options[:year].present?
        collection = collection.where(datacentre:  Client.find_by(symbol: options[:client_id]).id) if options[:client_id].present?
        collection
      end
    end

    def cached_clients
      Rails.cache.fetch("clients", expires_in: 1.month) do
        Client.all
      end
    end

    def cached_providers_response(options={})
      Rails.cache.fetch("provider_response", expires_in: 1.day) do
        Providers.where(options)
      end
    end

    def cached_datasets_clients_join(options={})
      Rails.cache.fetch("clients", expires_in: 1.day) do
        Dataset.joins(:clients).where("client.symbol" => "dataset.allocator")
      end
    end

    def cached_clients_response(options={})
      Rails.cache.fetch("clients_response", expires_in: 1.day) do
        # collection = cached_datasets_clients_joins
        collection.each do |line|
          dc = Client.find(line[:datacentre])
          line[:client_id] = dc.uid
          line[:client_name] = dc.name
        end

        collection.map{|doi| { id: doi[:id],  client_id: doi[:client_id],  name: doi[:client_name] }}.group_by { |d| d[:client_id] }.map{ |k, v| { id: k, title: v.first[:name], count: v.count} }
      end
    end

    def cached_years_response
      Rails.cache.fetch("years_datasets", :expires_in => 1.hour) do
        collection = cached_datasets
        collection.map{|doi| { id: doi[:id],  year: doi[:created].year }}.group_by { |d| d[:year] }.map{ |k, v| { id: k, title: k, count: v.count} }
      end
    end

    def cached_years_by_provider_response(id, options={})
      Rails.cache.fetch("years_response", expires_in: 1.day) do
        query = self.ds.where(is_active: true, allocator: id)
        years = query.group_and_count(Sequel.extract(:year, :created)).all
        years.map { |y| { id: y.values.first.to_s, title: y.values.first.to_s, count: y.values.last } }
             .sort { |a, b| b.fetch(:id) <=> a.fetch(:id) }
      end
    end

    def cached_client_response(id, options={})
      Rails.cache.fetch("client_response/#{id}", expires_in: 7.days) do
        Client.where(symbol: id).select(:id, :symbol, :name, :created).first
      end
    end

    def cached_clients_by_provider_response(id, options={})
      Rails.cache.fetch("client_by_provider_response/#{id}", expires_in: 1.day) do
        query = self.ds.where(is_active: true, allocator: id)
        query.limit(25).offset(0).order(:name)
      end
    end
  end
end
