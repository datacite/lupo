# frozen_string_literal: true

module Mds
  class DoisController < Mds::ApplicationController
    prepend_before_action :authenticate_mds_user!
    before_action :set_doi, only: %i[show destroy]

    def index
      result = Mds::DoiOperations.new(current_user: current_user).list
      render_result(result)
    end

    def show
      result = Mds::DoiOperations.new(current_user: current_user).get_url(@doi)
      render_result(result)
    end

    def update
      doi, url = parse_doi_and_url
      return head :bad_request if doi.blank? || url.blank?

      result = Mds::DoiOperations.new(current_user: current_user).put_url(doi, url: url)
      render_result(result)
    end

    def destroy
      result = Mds::DoiOperations.new(current_user: current_user).destroy(@doi)
      render_result(result)
    end

    private

    def set_doi
      @doi = validate_doi(params[:id])
      fail AbstractController::ActionNotFound if @doi.blank?
    end

    def parse_doi_and_url
      if (params[:id].present? || params[:doi].present?) && params[:url].present?
        [params[:id].presence || params[:doi], params[:url]]
      elsif request.raw_post.present?
        Mds::DoiOperations.extract_url(
          doi: validate_doi(params[:id]),
          data: request.raw_post,
        )
      else
        [nil, nil]
      end
    end

    def render_result(result)
      result.headers.each { |k, v| response.headers[k] = v }

      if result.status == 204
        head :no_content
      else
        render plain: result.body.to_s, status: result.status
      end
    end
  end
end
