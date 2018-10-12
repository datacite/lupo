class IndexController < ApplicationController
  include ActionController::MimeResponds

  prepend_before_action :authenticate_user!
  before_action :set_doi, only: [:show]
  
  def index
    authorize! :index, :Index
    render plain: ENV['SITE_TITLE']
  end

  # we support content negotiation in show action
  def show
    authorize! :show, @doi

    respond_to do |format|
      format.citation do
        # fetch formatted citation
        @doi.style = params[:style] || "apa"
        @doi.locale = params[:locale] || "en-US"
        render citation: @doi
      end
      format.any(:bibtex, :citeproc, :codemeta, :crosscite, :datacite, :datacite_json, :jats, :ris, :schema_org) { render request.format.to_sym => @doi }
      format.any { fail ActionController::UnknownFormat }
    end
  end

  # def routing_error
  #   fail ActionController::RoutingError
  # end

  protected

  def set_doi
    @doi = Doi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?
  end
end
