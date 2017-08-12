class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]

  # GET /prefixes
  def index
    if params["q"].nil?
      @prefixes = Prefix.__elasticsearch__.search "*"
    else
      @prefixes = Prefix.__elasticsearch__.search params["q"]
    end
    @prefixes = Prefix.all

    meta = { #total: @prefixes.total_entries,
             #total_pages: @prefixes.total_pages ,
             #page: page[:number].to_i,
            #  member_types: member_types,
            #  regions: regions,
            }
    paginate json: @prefixes, meta: meta,  each_serializer: PrefixSerializer,per_page: 25
  end

  # GET /prefixes/1
  def show
    render json: @prefix, include:['datacenters', 'members']
  end

  # POST /prefixes
  def create
    @prefix = Prefix.new(prefix_params)

    if @prefix.save
      render json: @prefix, status: :created, location: @prefix
    else
      render json: serialize(@prefix.errors), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /prefixes/1
  def update
    if @prefix.update(prefix_params)
      render json: @prefix
    else
      render json: serialize(@prefix.errors), status: :unprocessable_entity
    end
  end

  # DELETE /prefixes/1
  def destroy
    @prefix.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_prefix
      # @prefix = Prefix.find(params[:id])
      @prefix = Prefix.find_by(prefix: params[:id])
      fail ActiveRecord::RecordNotFound unless @prefix.present?
    end

    # Only allow a trusted parameter "white list" through.
    def prefix_params
      params.require(:data)
        .require(:attributes)
        .permit(:created, :prefix, :version)
      pf_params = ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
      pf_params
    end
end
