class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]

  # GET /prefixes
  def index
    @prefixes = Prefix.all

    paginate json: @prefixes , per_page: 25
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
      params[:data][:attributes] = params[:data][:attributes].transform_keys!{ |key| key.to_s.snakecase }

      params[:data].require(:attributes).permit(:created, :prefix, :version, :datacentre)
    end
end
