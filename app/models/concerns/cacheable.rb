module Cacheable
  extend ActiveSupport::Concern

  included do
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

    def cached_prefixes_totals params={}
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_prefixes_totals/#{params}", expires_in: 24.hours) do
          prefixes_totals params
        end
      else
        prefixes_totals params
      end
    end

    def cached_providers_totals params={}
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_providers_totals/#{params}", expires_in: 24.hours) do
          providers_totals params
        end
      else
        providers_totals params
      end
    end

    def cached_clients_totals params={}
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_clients_totals/#{params}", expires_in: 24.hours) do
          clients_totals params
        end
      else
        clients_totals params
      end
    end

    def cached_prefix_response(prefix, options={})
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("prefix_response/#{prefix}", expires_in: 24.hours) do
          Prefix.where(prefix: prefix).first
        end
      else
        Prefix.where(prefix: prefix).first
      end
    end

    def cached_resource_type_response(id)
      Rails.cache.fetch("resource_type_response/#{id}", expires_in: 1.month) do
        resource_type = ResourceType.where(id: id)
        resource_type.present? ? resource_type[:data] : nil
      end
    end

    def cached_alb_public_key(kid)
      Rails.cache.fetch("alb_public_key/#{kid}", expires_in: 1.day) do
        url = "https://public-keys.auth.elb.eu-west-1.amazonaws.com/" + kid
        response = Maremma.get(url)
        response.body.fetch("data", nil)
      end
    end
  end

  module ClassMethods
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
  end
end
