class DatacentersController < ApplicationController
  before_action :set_datacenter, only: [:show, :update, :destroy]

  # GET /datacenters
  def index
    @datacenters = Datacenter.all

    render json: @datacenters
  end

  # GET /datacenters/1
  def show
    render json: @datacenter
  end

  # POST /datacenters
  def create
    @datacenter = Datacenter.new(datacenter_params)

    if @datacenter.save
      render json: @datacenter, status: :created, location: @datacenter
    else
      render json: @datacenter.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /datacenters/1
  def update
    if @datacenter.update(datacenter_params)
      render json: @datacenter
    else
      render json: @datacenter.errors, status: :unprocessable_entity
    end
  end

  # DELETE /datacenters/1
  def destroy
    @datacenter.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_datacenter
      @datacenter = Datacenter.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def datacenter_params
      params.require(:datacenter).permit(:comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :allocator, :experiments)
    end
end
