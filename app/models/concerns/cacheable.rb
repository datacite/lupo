# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  included do
    def cached_metadata_count(options = {})
      Rails.cache.fetch(
        "cached_metadata_count/#{id}",
        expires_in: 6.hours, force: options[:force],
      ) do
        return [] if Rails.env.test?

        collection =
          instance_of?(Doi) ? Metadata.where(dataset: id) : Metadata

        years =
          collection.order("YEAR(metadata.created)").group(
            "YEAR(metadata.created)",
          ).
            count
        years.map { |k, v| { id: k, title: k, count: v } }
      end
    end

    def cached_media_count(options = {})
      Rails.cache.fetch(
        "cached_media_count/#{id}",
        expires_in: 6.hours, force: options[:force],
      ) do
        return [] if Rails.env.test?

        if instance_of?(Doi)
          collection = Media.where(dataset: id)
          return [] if collection.blank?
        else
          collection = Media
        end

        years =
          collection.order("YEAR(media.created)").group("YEAR(media.created)").
            count
        years.map { |k, v| { id: k, title: k, count: v } }
      end
    end

    def cached_prefixes_totals(params = {})
      if Rails.application.config.action_controller.perform_caching
        Rails.cache.fetch(
          "cached_prefixes_totals/#{params}",
          expires_in: 24.hours,
        ) { prefixes_totals params }
      else
        prefixes_totals params
      end
    end

    def cached_prefix_response(prefix, _options = {})
      uid = prefix.to_s
      return Prefix.where(uid: uid).first unless Rails.application.config.action_controller.perform_caching

      # Cache only the numeric id as a hint. Always re-load and verify uid so a
      # destroyed/recreated prefix cannot yield an orphan FK (common in tests that
      # reuse fixed uids like 10.17616 across before/after :all blocks).
      cached_id = Rails.cache.fetch("prefix_response/#{uid}", expires_in: 24.hours) do
        Prefix.where(uid: uid).pick(:id)
      end

      record = cached_id.present? ? Prefix.find_by(id: cached_id) : nil
      return record if record&.uid.to_s == uid

      Rails.cache.delete("prefix_response/#{uid}")
      found = Prefix.where(uid: uid).first
      if found
        Rails.cache.write("prefix_response/#{uid}", found.id, expires_in: 24.hours)
      end
      found
    end

    def cached_resource_type_response(id)
      Rails.cache.fetch("resource_type_response/#{id}", expires_in: 1.month) do
        resource_type = ResourceType.where(id: id)
        resource_type.present? ? resource_type[:data] : nil
      end
    end

    def cached_get_doi_ra(prefix)
      Rails.cache.fetch("ras/#{prefix}", expires_in: 1.month) do
        get_doi_ra(prefix)
      end
    end

    def cached_alb_public_key(kid)
      Rails.cache.fetch("alb_public_key/#{kid}", expires_in: 1.day) do
        url = "https://public-keys.auth.elb.eu-west-1.amazonaws.com/" + kid
        response = Maremma.get(url)
        response.body.fetch("data", nil)
      end
    end

    def cached_globus_public_key
      Rails.cache.fetch("globus_public_key", expires_in: 1.month) do
        url = "https://auth.globus.org/jwk.json"
        response = Maremma.get(url)
        response.body.dig("data", "keys", 0)
      end
    end
  end

  module ClassMethods
    def cached_metadata_count
      Rails.cache.fetch("cached_metadata_count", expires_in: 6.hours) do
        return [] if Rails.env.test?

        years =
          Metadata.order("YEAR(metadata.created)").group(
            "YEAR(metadata.created)",
          ).
            count
        years.map { |k, v| { id: k, title: k, count: v } }
      end
    end

    def cached_media_count
      Rails.cache.fetch("cached_media_count", expires_in: 6.hours) do
        return [] if Rails.env.test?

        years =
          Media.order("YEAR(media.created)").group("YEAR(media.created)").count
        years.map { |k, v| { id: k, title: k, count: v } }
      end
    end

    def cached_get_doi_ra(prefix)
      Rails.cache.fetch("ras/#{prefix}", expires_in: 1.month) do
        get_doi_ra(prefix)
      end
    end
  end
end
