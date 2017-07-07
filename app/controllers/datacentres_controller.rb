class DatacentresController < ApplicationController
# class DatacentresController < JSONAPI::ResourceController
  # before_action :authenticate_request #, only: [:create, :update, :destroy]
  before_action :set_datacentre, only: [:show, :update, :destroy]
  load_and_authorize_resource

  # GET /datacentres
  def index

    collection = Datacentre
    collection = collection.query(params[:query]) if params[:query]

    if params[:allocator].present?
      collection = collection.where(allocator: params[:allocator])
      @allocator = collection.where(allocator: params[:allocator]).group(:allocator).count.first
    end

    if params[:allocator].present?
      allocators = [{ id: params[:allocator],
                 member: params[:allocator],
                 count: Datacentre.where(allocator: params[:allocator]).count }]
    else
      allocators = Datacentre.where.not(allocator: nil).order("allocator DESC").group(:allocator).count
      allocators = allocators.map { |k,v| { id: k.id.to_s, member: k.symbol.to_s, count: v } }
    end
    #
    page = params[:page] || { number: 1, size: 1000 }
    #
    @datacentres = Datacentre.order(:allocator).page(page[:number]).per_page(page[:size])
    #
    meta = { total: @datacentres.total_entries,
             total_pages: @datacentres.total_pages ,
             page: page[:number].to_i,
            #  member_types: member_types,
            #  regions: regions,
             members: allocators }

    paginate json: @datacentres, meta: meta, per_page: 25
  end

  # GET /datacentres/1
  def show
    render json: @datacentre, include:['allocators', 'prefixes']
  end

  # POST /datacentres
  def create
    pp = datacentre_params
    pp[:allocator] = Allocator.find_by(symbol: datacentre_params[:allocator])
    # puts pp[:allocator].inspect
    puts "marafa"
    @datacentre = Datacentre.new(pp)

    if @datacentre.save
      render json: @datacentre, status: :created, location: @datacentre
    else
      render json: @datacentre.errors, status: :unprocessable_entity
      # render json: ErrorSerializer.serialize(@datacentre.errors) #, status: :unprocessable_entity
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
