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

    def cached_doi_citations_response(doi)
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_doi_citations_response/#{doi}", expires_in: 24.hours) do
          EventsQuery.new.doi_citations(doi)
        end
      else
        EventsQuery.new.doi_citations(doi)
      end
    end

    def cached_doi_views_response(doi)
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_doi_views_response/#{doi}", expires_in: 24.hours) do
          EventsQuery.new.doi_views(doi)
        end
      else
        EventsQuery.new.doi_views(doi)
      end
    end

    def cached_doi_downloads_response(doi)
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_doi_downloads_response/#{doi}", expires_in: 24.hours) do
          EventsQuery.new.doi_downloads(doi)
        end
      else
        EventsQuery.new.doi_downloads(doi)
      end
    end

    def cached_citations_histogram_response(doi)
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_citations_histogram_response/#{doi}", expires_in: 24.hours) do
          EventsQuery.new.citations_histogram(doi)
        end
      else
        EventsQuery.new.citations_histogram(doi)
      end
    end

    def cached_views_histogram_response(doi)
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_views_histogram_response/#{doi}", expires_in: 24.hours) do
          EventsQuery.new.views_histogram(doi)
        end
      else
        EventsQuery.new.views_histogram(doi)
      end
    end

    def cached_downloads_histogram_response(doi)
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch("cached_downloads_histogram_response/#{doi}", expires_in: 24.hours) do
          EventsQuery.new.downloads_histogram(doi)
        end
      else
        EventsQuery.new.downloads_histogram(doi)
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
