class IndexController < ApplicationController
  include ActionController::MimeResponds

  before_action :set_doi, only: [:show]

  def index
    render plain: ENV['SITE_TITLE']
  end

  # we support content negotiation in show action
  def show
    respond_to do |format|
      format.citation do
        # fetch formatted citation
        options = {
          style: params[:style] || "apa",
          locale: params[:locale] || "en-US" }

        citation_url = ENV["CITEPROC_URL"] + "?" + URI.encode_www_form(options)
        response = Maremma.post citation_url, content_type: 'json', data: @doi.citeproc

        render plain: response.body.fetch("data", nil)
      end
      format.any(:bibtex, :citeproc, :codemeta, :datacite, :datacite_json, :jats, :ris, :schema_org) { render request.format.to_sym => @doi }
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
