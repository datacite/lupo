class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  # GET /prefixes
  def index
    collection = Prefix.all

    # pagination
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @prefixes = collection.order(created: :desc).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @prefixes.total_pages,
             page: page[:number].to_i }

    render jsonapi: collection, meta: meta, include: @include
  end

  # GET /prefixes/1
  def show
    render jsonapi: @prefix, include: @include, serializer: PrefixSerializer
  end

  # POST /prefixes
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @prefix = Prefix.new(safe_params.except(:type))
      authorize! :create, @prefix

      if @prefix.save
        render jsonapi: @prefix, status: :created, location: @prefix
      else
        render jsonapi: serialize(@prefix.errors), status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /prefixes/1
  def update
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @prefix.update_attributes(safe_params.except(:type))
        render jsonapi: @prefix
      else
        render json: serialize(@prefix.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /prefixes/1
  def destroy
    @prefix.destroy
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = nil
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_prefix
    @prefix = Prefix.where(prefix: params[:id]).first

    # fallback to call handle server, i.e. for prefixes not from DataCite
    @prefix = Handle.where(id: params[:id]) unless @prefix.present?
    Rails.logger.info @prefix.inspect
    fail ActiveRecord::RecordNotFound unless @prefix.present?
  end

  def safe_params
    attributes = [:uid, :prefix, :version]
    params.require(:data).permit(:id, :type, attributes: attributes)
  end
  # Only allow a trusted parameter "white list" through.
  # def prefix_params
  #   params.require(:data)
  #     .require(:attributes)
  #     .permit(:created, :prefix, :version)
  #   pf_params = ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
  #   pf_params
  # end
end
