class MediaController < ApplicationController
  before_action :set_media, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]
  # GET /media
  def index

    response = Media.get_all(params)

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = response[:collection].count

    @media = response[:collection].order(:created).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @media.total_pages,
             page: page[:number].to_i,
             media_types: response[:media_types],
             years: response[:years] }

    render jsonapi: @media, meta: meta, include: ["dataset"]
  end

  # GET /media/1
  def show
    render jsonapi: @media, include: @include
  end

  # POST /media
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @media = Media.new(safe_params.except(:type))
      authorize! :create, @media

      if @media.save
        render json: @media, status: :created, location: @media
      else
        render json: serialize(@media.errors), status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /media/1
  def update
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @media.update_attributes(safe_params.except(:type))
        render json: @media
      else
        render json: serialize(@media.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /media/1
  def destroy
    @media.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_media
      @media = Media.where(id: params[:id]).first
      fail ActiveRecord::RecordNotFound unless @media.present?
    end

    # Only allow a trusted parameter "white list" through.
    def safe_params
      attributes = [:created, :updated, :dataset_id, :version, :url, :media_type]
      params.require(:data).permit(:id, :type, attributes: attributes)
    end
end
