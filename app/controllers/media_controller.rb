class MediaController < ApplicationController
  before_action :set_media, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]
  # GET /media
  def index

    collection = Media

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(created) = ?', params[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(created) DESC").group("YEAR(created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    if params[:media_type].present?
      media_types = [{ id: params[:media_type],
                 title: params[:media_type],
                 count: collection.where('media_type = ?', params[:media_type]).count }]
    else
      media_types = collection.where.not(created: nil).order("media_type DESC").group("media_type").count
      media_types = media_types.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @media = collection.order(:created).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @media.total_pages,
             page: page[:number].to_i,
             media_types: media_types,
             years: years }

    render jsonapi: @media, meta: meta, include: @include
  end

  # GET /media/1
  def show
    render jsonapi: @media
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
      @media = Media.where(dataset: params[:id]).first
      fail ActiveRecord::RecordNotFound unless @media.present?
    end

    # Only allow a trusted parameter "white list" through.
    def safe_params
      attributes = [:created, :updated, :dataset, :version, :url, :media_type]
      params.require(:data).permit(:id, :type, attributes: attributes)
    end
end
