class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  # GET /prefixes
  def index
    options = {}
    params[:query] ||= "*"
    response = Prefix.search(params[:query], options)

    # pagination
    page = (params.dig(:page, :number) || 1).to_i
    per_page =(params.dig(:page, :size) || 25).to_i
    total = response.size
    total_pages = (total.to_f / per_page).ceil
    collection = response.page(page).per(per_page).order(created: :desc)

    # extract source hash from each result to feed into serializer
    # collection = collection.map { |m| m[:_source] }

    meta = { total: total,
             total_pages: total_pages,
             page: page }

    render jsonapi: collection, meta: meta
  end

  # GET /prefixes/1
  def show
    render jsonapi: @prefix, include:['datacenters', 'members']
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_prefix
      @prefix = Prefix.where(prefix: params[:id]).first
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
