# frozen_string_literal: true

class IndexController < ApplicationController
  include ActionController::MimeResponds

  def index
    render plain: ENV["SITE_TITLE"]
  end

  def show
    doi = Doi.where(doi: params[:id], aasm_state: "findable").first
    fail ActiveRecord::RecordNotFound if doi.blank?

    respond_to do |format|
      format.html do
        # forward to URL registered in handle system for no content negotiation
        redirect_to doi.url, status: :see_other
      end
      format.citation do
        # extract optional style and locale from header
        headers =
          request.headers["HTTP_ACCEPT"].to_s.gsub(/\s+/, "").split(";", 3).
            reduce({}) do |sum, item|
            sum[:style] = item.split("=").last if item.start_with?("style")
            sum[:locale] = item.split("=").last if item.start_with?("locale")
            sum
          end
        render citation: doi,
               style: params[:style] || headers[:style] || "apa",
               locale: params[:locale] || headers[:locale] || "en-US"
      end
      format.any(
        :bibtex,
        :citeproc,
        :codemeta,
        :crosscite,
        :datacite,
        :datacite_json,
        :jats,
        :ris,
        :schema_org,
      ) { render request.format.to_sym => doi }
      header = %w[
        doi
        url
        registered
        state
        resourceTypeGeneral
        resourceType
        title
        author
        publisher
        publicationYear
      ]
      format.csv { render request.format.to_sym => doi, header: header }
    end
  rescue ActionController::UnknownFormat, ActionController::RoutingError
    # forward to URL registered in handle system for unrecognized format
    redirect_to doi.url, status: :see_other, allow_other_host: true
  end

  def routing_error
    fail ActiveRecord::RecordNotFound
  end

  def method_not_allowed
    response.set_header("Allow", "POST")
    render json: {
      "message": "This endpoint only supports POST requests.",
    }.to_json,
           status: :method_not_allowed
  end
end
