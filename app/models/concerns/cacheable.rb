module Cacheable
  extend ActiveSupport::Concern

  included do
    def cached_doi_count(options={})
      Rails.cache.fetch("cached_doi_count/#{id}", expires_in: 6.hours, force: options[:force]) do
        return [] if Rails.env.test?

        if self.class.name == "Provider" && symbol != "ADMIN"
          collection = Doi.joins(:client).where("datacentre.allocator = ?", id)
        elsif self.class.name == "Client"
          collection = Doi.where(datacentre: id)
        else
          collection = Doi
        end

        years = collection.order("YEAR(dataset.created)").group("YEAR(dataset.created)").count
        years = years.map { |k,v| { id: k, title: k, count: v } }
      end
    end

    def cached_client_response(id, options={})
      Rails.cache.fetch("client_response/#{id}", expires_in: 1.day) do
        Client.where(symbol: id).first
      end
    end

    def cached_prefix_response(prefix, options={})
      Rails.cache.fetch("prefix_response/#{prefix}", expires_in: 7.days) do
        Prefix.where(prefix: prefix).first
      end
    end

    def cached_providers
      Rails.cache.fetch("providers", expires_in: 1.day) do
        Provider.all.select(:id, :symbol, :name, :created)
      end
    end

    def cached_provider_response(symbol)
      Rails.cache.fetch("provider_response/#{symbol}", expires_in: 1.day) do
        Provider.where(symbol: symbol).first
      end
    end

    def cached_member_response(id)
      Rails.cache.fetch("member_response/#{id}", expires_in: 1.day) do
        Member.where(id: id)
      end
    end

    def cached_repository_response(id, options={})
      Rails.cache.fetch("repository_response/#{id}", expires_in: 7.days) do
        Repository.where(id: id)
      end
    end
  end

  module ClassMethods
    def cached_doi_response(id: nil, item: nil)
      Rails.cache.fetch(id) do
        DoiSearch.new(input: Base64.decode64(item.fetch("xml", "PGhzaD48L2hzaD4=\n")),
                      from: "datacite",
                      doi: item.fetch("doi", nil),
                      sandbox: !Rails.env.production?,
                      state: item.fetch("state", nil),
                      date_registered: item.fetch("minted", nil),
                      date_updated: item.fetch("updated", nil),
                      provider_id: item.fetch("allocator_symbol", "").downcase,
                      client_id: item.fetch("datacentre_symbol", "").downcase,
                      url: item.fetch("url", nil))
      end
    end

    def cached_providers
      Rails.cache.fetch("providers", expires_in: 1.day) do
        Provider.all.select(:id, :symbol, :name, :updated)
      end
    end

    # def cached_clients
    #   Rails.cache.fetch("clients", expires_in: 1.day) do
    #     Client.all.select(:id, :symbol, :name, :updated)
    #   end
    # end

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
      Rails.cache.fetch("client_response/#{id}", expires_in: 1.day) do
        Client.where(symbol: id).first
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
