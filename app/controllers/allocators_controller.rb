class AllocatorsController < ApplicationController
  before_action :set_allocator, only: [:show, :update, :destroy]

  # GET /allocators
  def index
    @allocators = Allocator.all

    paginate json: @allocators, include: 'datacentres, prefixes', per_page: 25
  end

  # GET /allocators/1
  def show
      render json: @allocator, include: 'datacentres, prefixes'
  end

  # POST /allocators
  def create
    @allocator = Allocator.new(allocator_params)

    if @allocator.save
      render json: @allocator, status: :created, location: @allocator
    else
      render json: @allocator.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /allocators/1
  def update
    if @allocator.update(allocator_params)
      render json: @allocator
    else
      render json: @allocator.errors, status: :unprocessable_entity
    end
  end

  # DELETE /allocators/1
  def destroy
    @allocator.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_allocator
      @allocator = Allocator.find_by(symbol: params[:id])
      fail ActiveRecord::RecordNotFound unless @allocator.present?
    end

    # Only allow a trusted parameter "white list" through.
    def allocator_params

      params[:data][:attributes] = params[:data][:attributes].transform_keys!{ |key| key.to_s.snakecase }
      if params[:data][:attributes][:password]
          params[:data][:attributes][:password] = Digest::SHA256.hexdigest params[:data][:attributes][:password] + "{" + ENV["SESSION_ENCRYPTED_COOKIE_SALT"] + "}"
      end

      params[:data].require(:attributes).permit(:comments, :contact_email, :contact_name, :description, :member_type, :year, :image, :region, :country_code, :website, :logo, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :password, :role_name, :symbol, :version, :experiments)
    end
end
