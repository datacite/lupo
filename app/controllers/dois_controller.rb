class DoisController < ApplicationController
  before_action :set_doi, only: [:show, :update, :destroy]
  before_action :set_include
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  # # # GET /datasets
  def index

    # page = params[:page] || {}
    # page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    # page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 1000
    # total = collection.count
    #
    # @dois = collection.order(:name).page(page[:number]).per(page[:size])
    # meta = { total: total,
    #          total_pages: @dois.total_pages,
    #          page: page[:number].to_i,
    #          provider_types: provider_types,
    #          regions: regions,
    #          years: years }
    # #
    # render jsonapi: @dois, meta: meta

    @dois = Doi.where(params)
    render jsonapi: @dois[:data], meta: @dois[:meta], include: @include

    # dois = Maremma.get("https://api.test.datacite.org/dois")
    # render jsonapi: dois.to_h[:body]
  end

  # # # GET /datasets/1
  def show
    render jsonapi: @doi[:data], include: @include
  end

  protected

  # Use callbacks to share common setup or constraints between actions.
  def set_doi
    @doi = Doi.where(params)
    fail ActiveRecord::RecordNotFound unless @doi.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ["client,provider,resource_type"]
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
    def safe_params
      attributes = [:uid, :created, :doi, :is_active, :version, :client_id]
      params.require(:data).permit(:id, :type, attributes: attributes)
    end
end
