# frozen_string_literal: true

module Mds
  class MediaController < Mds::ApplicationController
    prepend_before_action :authenticate_mds_user!
    before_action :set_doi
    before_action :set_media, only: %i[show destroy]

    def index
      result = Mds::MediaOperations.new(current_user: current_user).list(@doi)
      render_result(result)
    end

    def show
      result =
        Mds::MediaOperations.new(current_user: current_user).show(@doi, @id)
      render_result(result)
    end

    def create
      result =
        Mds::MediaOperations.new(current_user: current_user).create(
          @doi,
          data: request.raw_post,
        )
      render_result(result)
    end

    def destroy
      result =
        Mds::MediaOperations.new(current_user: current_user).destroy(@doi, @id)
      render_result(result)
    end

    private

    def set_doi
      # Flat /media/:doi_id and nested /doi/:doi_id/media both expose :doi_id.
      raw = params[:doi_id]
      fail AbstractController::ActionNotFound if raw.blank?

      @doi = validate_doi(raw)
      fail AbstractController::ActionNotFound if @doi.blank?
    end

    def set_media
      @id = params[:id]
      fail AbstractController::ActionNotFound if @id.blank?
    end

    def render_result(result)
      if result.status == 204
        head :no_content
      else
        render plain: result.body.to_s, status: result.status
      end
    end
  end
end
