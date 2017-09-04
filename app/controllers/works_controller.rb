class WorksController < ApplicationController
  before_action :set_dataset, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  # # # GET /datasets
  def index

    # page = params[:page] || {}
    # page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    # page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 1000
    # total = collection.count
    #
    # @works = collection.order(:name).page(page[:number]).per(page[:size])
    # meta = { total: total,
    #          total_pages: @works.total_pages,
    #          page: page[:number].to_i,
    #          provider_types: provider_types,
    #          regions: regions,
    #          years: years }
    # #
    # render jsonapi: @works, meta: meta

    @works = Work.where(params)
    render jsonapi: @works[:data], meta: @works[:meta], include: @include, each_serializer: WorksSerializer

    # works = Maremma.get("https://api.test.datacite.org/works")
    # render jsonapi: works.to_h[:body]
  end

  # # # GET /datasets/1
  def show
    render jsonapi: @dataset
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dataset
      @dataset = Dataset.where(doi: params[:id]).first
      fail ActiveRecord::RecordNotFound unless @dataset.present?
    end


  private

  # Only allow a trusted parameter "white list" through.
    def safe_params
      attributes = [:uid, :created, :doi, :is_active, :version, :client_id]
      params.require(:data).permit(:id, :type, attributes: attributes)
    end
end
