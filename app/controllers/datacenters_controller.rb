class DatacentersController < ApplicationController
# class DatacentersController < JSONAPI::ResourceController
  # before_action :authenticate_request #, only: [:create, :update, :destroy]

  before_action :set_datacenter, only: [:show, :update, :destroy]
  load_and_authorize_resource

  # GET /datacenters
  def index
    @datacenters = Datacenter.get_all(params)
    meta = { total: @datacenters.total_entries,
            #  total_pages: @datacenters.total_pages ,
            #  page: page[:number].to_i,
            #  member_types: member_types,
            #  regions: regions,
            #  members: allocators
           }

    paginate json: @datacenters, meta: meta,  per_page: 25
  end

  # GET /datacenters/1
  def show
    render json: @datacenter, include:['member', 'prefixes']
  end

  # POST /datacenters
  def create
    @datacenter = Datacenter.new(datacenter_params)

    if @datacenter.save
      render json: @datacenter, status: :created, include:['datasets', 'prefixes', 'member'], location: @datacenter
    else
      render json: serialize(@datacenter.errors), status: :unprocessable_entity
      # render json: ErrorSerializer.serialize(@datacenter.errors) #, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /datacenters/1
  def update
    if @datacenter.update(datacenter_params)
      render json: @datacenter,  include:['datasets', 'prefixes', 'member']
    else
      render json: serialize(@datacenter.errors), status: :unprocessable_entity
    end
  end

  # DELETE /datacenters/1
  def destroy
    @datacenter.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_datacenter
      # @datacenter = Datacenter.find(params[:id])
      @datacenter = Datacenter.find_by(symbol: params[:id])
      fail ActiveRecord::RecordNotFound unless @datacenter.present?
    end

    # Only allow a trusted parameter "white list" through.
    def datacenter_params
      params[:data][:attributes] = params[:data][:attributes].transform_keys!{ |key| key.to_s.snakecase }

      dc_params = params[:data][:attributes].permit(:comments, :contact_email, :contact_name, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :password, :role_name, :datacenter_id, :version, :member_id, :experiments)
      allocator = Member.find_by(symbol: dc_params[:member_id])
      fail("member_id Not found") unless allocator.present?
      dc_params[:allocator] = allocator.id
      dc_params[:symbol] = dc_params[:datacenter_id]
      dc_params
    end
end
