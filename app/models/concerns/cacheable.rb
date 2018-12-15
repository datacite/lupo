module Cacheable
  extend ActiveSupport::Concern

  included do
    def cached_doi_count(options={})
      Rails.cache.fetch("cached_doi_count/#{id}", expires_in: 24.hours, force: options[:force]) do
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
    
    def cached_metadata_count(options={})
      Rails.cache.fetch("cached_metadata_count/#{id}", expires_in: 6.hours, force: options[:force]) do
        return [] if Rails.env.test?

        if self.class.name == "Doi"
          collection = Metadata.where(dataset: id)
        else
          collection = Metadata
        end

        years = collection.order("YEAR(metadata.created)").group("YEAR(metadata.created)").count
        years = years.map { |k,v| { id: k, title: k, count: v } }
      end
    end

    def cached_media_count(options={})
      Rails.cache.fetch("cached_media_count/#{id}", expires_in: 6.hours, force: options[:force]) do
        return [] if Rails.env.test?

        if self.class.name == "Doi"
          collection = Media.where(dataset: id)
          return [] if collection.blank?
        else
          collection = Media
        end

        years = collection.order("YEAR(media.created)").group("YEAR(media.created)").count
        years = years.map { |k,v| { id: k, title: k, count: v } }
      end
    end

    def fetch_cached_metadata_version
      if updated.present? && Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_metadata_version/#{doi}-#{updated.iso8601}") do
          current_metadata ? current_metadata.metadata_version : 0
        end
      else
        current_metadata ? current_metadata.metadata_version : 0
      end
    end

    def cached_client_response(id, options={})
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("client_response/#{id}", expires_in: 1.day) do
          Client.where(symbol: id).first
        end
      else
        Client.where(symbol: id).first
      end
    end

    def cached_prefix_response(prefix, options={})
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("prefix_response/#{prefix}", expires_in: 7.days) do
          Prefix.where(prefix: prefix).first
        end
      else
        Prefix.where(prefix: prefix).first
      end
    end

    def cached_provider_response(id, options={})
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("provider_response/#{id}", expires_in: 1.day) do
          Provider.where(symbol: id).first
        end
      else
        Provider.where(symbol: id).first
      end
    end

    def cached_providers
      Rails.cache.fetch("providers", expires_in: 1.day) do
        Provider.all.select(:id, :symbol, :name, :created)
      end
    end

    def cached_member_response(id)
      Rails.cache.fetch("member_response/#{id}", expires_in: 12.hours) do
        member = Member.where(id: id)
        member.present? ? member[:data] : nil
      end
    end

    def cached_resource_type_response(id)
      Rails.cache.fetch("resource_type_response/#{id}", expires_in: 1.month) do
        resource_type = ResourceType.where(id: id)
        resource_type.present? ? resource_type[:data] : nil
      end
    end

    def cached_repository_response(id, options={})
      Rails.cache.fetch("repository_response/#{id}", expires_in: 1.day) do
        url = Rails.env.production? ? "https://api.datacite.org" : "https://api.test.datacite.org"
        response = Maremma.get(url + "/repositories/" + id)
        attributes = response.body.dig("data", "attributes").to_h
        attributes = attributes.transform_keys! { |key| key.tr('-', '_') }
        attributes.merge("id" => id, "cache_key" => "repositories/#{id}-#{attributes["updated"]}")
      end
    end
  end

  module ClassMethods
    def cached_providers
      Rails.cache.fetch("providers", expires_in: 1.day) do
        Provider.all.select(:id, :symbol, :name, :updated)
      end
    end

    def cached_metadata_count
      Rails.cache.fetch("cached_metadata_count", expires_in: 6.hours) do
        return [] if Rails.env.test?

        years = Metadata.order("YEAR(metadata.created)").group("YEAR(metadata.created)").count
        years = years.map { |k,v| { id: k, title: k, count: v } }
      end
    end

    def cached_media_count
      Rails.cache.fetch("cached_media_count", expires_in: 6.hours) do
        return [] if Rails.env.test?

        years = Media.order("YEAR(media.created)").group("YEAR(media.created)").count
        years = years.map { |k,v| { id: k, title: k, count: v } }
      end
    end

    # def cached_clients
    #   Rails.cache.fetch("clients", expires_in: 1.day) do
    #     Client.all.select(:id, :symbol, :name, :updated)
    #   end
    # end

    def cached_providers_response(options={})
      Rails.cache.fetch("provider_response", expires_in: 1.day) do
        Providers.where(options)
      end
    end

    def cached_provider_response(symbol)
      Rails.cache.fetch("provider_response/#{symbol}", expires_in: 1.day) do
        Provider.where(symbol: symbol).first
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

    def cached_client_response(id, options={})
      Rails.cache.fetch("client_response/#{id}", expires_in: 1.day) do
        Client.where(symbol: id).first
      end
    end
  end
end
