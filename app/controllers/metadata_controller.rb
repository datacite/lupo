class MetadataController < ApplicationController
  before_action :set_metadata, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]
  # GET /metadata
  def index
    collection = Metadata

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(created) = ?', params[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(created) DESC").group("YEAR(created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    if params[:metadata_version].present?
      metadata_versions = [{ id: params[:metadata_version],
                 title: params[:metadata_version],
                 count: collection.where('metadata_version = ?', params[:metadata_version]).count }]
    else
      metadata_versions = collection.where.not(metadata_version: nil).order("metadata_version DESC").group("metadata_version").count
      metadata_versions = metadata_versions.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @metadata = collection.order(:created).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @metadata.total_pages,
             page: page[:number].to_i,
             metadata_versions: metadata_versions,
             years: years }

    render jsonapi: @metadata, meta: meta, include: @include
  end

  # GET /metadata/1
  def show
    render jsonapi: @metadata
  end

  # POST /metadata
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @metadata = Metadata.new(safe_params.except(:type))
      authorize! :create, @metadata

      if @metadata.save
        render json: @metadata, status: :created, location: @metadata
      else
        render json: serialize(@metadata.errors), status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /metadata/1
  def update
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @metadata.update_attributes(safe_params.except(:type))
        render json: @metadata
      else
        render json: serialize(@metadata.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /metadata/1
  def destroy
    @metadata.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_metadata
      @metadata = Metadata.where(id: params[:id]).first
      fail ActiveRecord::RecordNotFound unless @metadata.present?
    end

    # Only allow a trusted parameter "white list" through.
    def safe_params
      attributes = [:created, :version, :metadata_version, :dataset, :is_converted_by_mds, :namespace, :xml]
      params.require(:data).permit(:id, :type, attributes: attributes)
    end
end
