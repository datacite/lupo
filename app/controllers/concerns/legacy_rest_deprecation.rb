# frozen_string_literal: true

module LegacyRestDeprecation
  extend ActiveSupport::Concern

  LEGACY_REST_SUNSET = "Wed, 01 Jul 2026 00:00:00 GMT"

  included do
    before_action :reject_if_legacy_rest_disabled, only: %i[index show]
  end

  class_methods do
    def legacy_replacement(path)
      @legacy_replacement_path = path
    end

    def legacy_replacement_path
      @legacy_replacement_path
    end
  end

  private
    def reject_if_legacy_rest_disabled
      return unless legacy_rest_disabled?

      replacement = self.class.legacy_replacement_path
      detail =
        if replacement.present?
          "Use GET #{replacement} instead of GET #{request.path}."
        else
          "This endpoint has been deprecated. See the DataCite REST API documentation for supported endpoints."
        end

      response.headers["Sunset"] = LEGACY_REST_SUNSET

      render json: {
        errors: [{
          status: "410",
          title: "This endpoint has been deprecated and is no longer available.",
          detail: detail,
        }],
      }.to_json,
             status: :gone
    end

    def legacy_rest_disabled?
      ENV["DISABLE_LEGACY_REST"].to_s.downcase.in?(%w[true 1])
    end
end
