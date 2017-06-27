class DatacentresController < ApplicationController
# class DatacentresController < JSONAPI::ResourceController
  before_action :set_datacentre, only: [:show, :update, :destroy]

  # GET /datacentres
  def index
    @datacentres = Datacentre.all

    paginate json: @datacentres, include:'allocators, prefixes', per_page: 25
  end

  # GET /datacentres/1
  def show
    render json: @datacentre, include:['allocators', 'prefixes']
  end

  # POST /datacentres
  def create
    pp = datacentre_params
    pp[:allocator] = Allocator.find(datacentre_params[:allocator])
    @datacentre = Datacentre.new(pp)

    if @datacentre.save
      render json: @datacentre, status: :created, location: @datacentre
    else
      render json: @datacentre.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /datacentres/1
  def update
    pp = datacentre_params
    pp[:allocator] = Allocator.find(datacentre_params[:allocator])

    if @datacentre.update(pp)
      render json: @datacentre
    else
      render json: @datacentre.errors, status: :unprocessable_entity
    end
  end

  # DELETE /datacentres/1
  def destroy
    @datacentre.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_datacentre
      # @datacentre = Datacentre.find(params[:id])
      @datacentre = Datacentre.find_by(symbol: params[:id])
      fail ActiveRecord::RecordNotFound unless @datacentre.present?
    end

    # Only allow a trusted parameter "white list" through.
    def datacentre_params
      params[:data][:attributes] = params[:data][:attributes].transform_keys!{ |key| key.to_s.snakecase }

      params[:data].require(:attributes).permit(:comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :allocator, :experiments)
    end
end
