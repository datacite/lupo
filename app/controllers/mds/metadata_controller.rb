# frozen_string_literal: true

module Mds
  class MetadataController < Mds::ApplicationController
    prepend_before_action :authenticate_mds_user!
    before_action :set_doi, only: %i[destroy]

    def show
      @doi = validate_doi(params[:doi_id])
      fail AbstractController::ActionNotFound unless @doi.present?

      result = Mds::MetadataOperations.new(current_user: current_user).get(@doi)

      if result.status == 204
        head :no_content
      elsif result.success?
        render xml: result.body, status: :ok
      else
        render plain: result.body.to_s, status: result.status
      end
    end

    def create
      if request.content_type.to_s.include?("application/x-www-form-urlencoded")
        render plain: "Content type application/x-www-form-urlencoded is not supported",
               status: :unsupported_media_type
        return
      end

      data = request.raw_post
      result =
        Mds::MetadataOperations.new(current_user: current_user).create(
          doi_string: params[:doi_id],
          data: data,
          number: params[:number],
        )

      result.headers.each { |k, v| response.headers[k] = v }
      render plain: result.body.to_s, status: result.status
    end

    def destroy
      result = Mds::MetadataOperations.new(current_user: current_user).destroy(@doi)
      render plain: result.body.to_s, status: result.status
    end

    private

    def set_doi
      @doi = validate_doi(params[:doi_id])
      fail AbstractController::ActionNotFound unless @doi.present?
    end
  end
end
