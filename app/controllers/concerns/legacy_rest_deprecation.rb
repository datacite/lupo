# frozen_string_literal: true

module LegacyRestDeprecation
  extend ActiveSupport::Concern

  included do
    before_action :reject_if_past_legacy_sunset, only: %i[index show]
    after_action :set_legacy_sunset_headers, only: %i[index show]

    rescue_from ActiveRecord::RecordNotFound, with: :legacy_render_not_found
  end

  class_methods do
    def legacy_sunset_at(time)
      @legacy_sunset_at = time
    end

    def legacy_sunset_at_value
      @legacy_sunset_at
    end

    def legacy_sunset_link(url)
      @legacy_sunset_link = url
    end

    def legacy_sunset_link_value
      @legacy_sunset_link
    end

    def legacy_replacement(path)
      @legacy_replacement_path = path
    end

    def legacy_replacement_path
      @legacy_replacement_path
    end
  end

  private
    def reject_if_past_legacy_sunset
      return unless past_legacy_sunset?

      set_legacy_sunset_link_header

      replacement = self.class.legacy_replacement_path
      detail =
        if replacement.present?
          "Use GET #{replacement} instead of GET #{request.path}."
        else
          "This endpoint has been deprecated. See the DataCite REST API documentation for supported endpoints."
        end

      render json: {
        errors: [{
          status: "410",
          title: "This endpoint has been deprecated and is no longer available.",
          detail: detail,
        }],
      }.to_json,
             status: :gone
    end

    def set_legacy_sunset_headers
      return if past_legacy_sunset?

      response.headers["Sunset"] = self.class.legacy_sunset_at_value.httpdate
      set_legacy_sunset_link_header
    end

    def set_legacy_sunset_link_header
      url = self.class.legacy_sunset_link_value
      return if url.blank?

      response.headers["Link"] = %(<#{url}>; rel="sunset")
    end

    def legacy_render_not_found(_exception)
      set_legacy_sunset_headers unless past_legacy_sunset?

      render json: {
        errors: [{
          status: "404",
          title: "The resource you are looking for doesn't exist.",
        }],
      }.to_json,
             status: :not_found
    end

    def past_legacy_sunset?
      sunset_at = self.class.legacy_sunset_at_value
      return false if sunset_at.blank?

      Time.current.utc >= sunset_at
    end
end
