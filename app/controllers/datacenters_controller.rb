class DatacentersController < ApplicationController
  before_action :set_datacenter, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  # include helper module for caching infrequently changing resources
  include Cacheable

  def index
    collection = Datacenter

    if params[:id].present?
      collection = collection.where(symbol: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    # cache members for faster queries
    if params["member-id"].present?
      member = cached_member_response(params["member-id"].upcase)
      collection = collection.where(allocator: member.id)
    end
    collection = collection.where('YEAR(created) = ?', params[:year]) if params[:year].present?

    # calculate facet counts after filtering
    if params["member-id"].present?
      members = [{ id: params["member-id"],
                   title: member.name,
                   count: collection.where(allocator: member.id).count }]
    else
      members = collection.where.not(allocator: nil).group(:allocator).count
      Rails.logger.info members.inspect
      members = members
                  .sort { |a, b| b[1] <=> a[1] }
                  .map do |i|
                         member = cached_members.find { |m| m.id == i[0] }
                         { id: member.symbol.downcase, title: member.name, count: i[1] }
                       end
    end
    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(created) = ?', params[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(created) DESC").group("YEAR(created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @datacenters = collection.order(:name).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @datacenters.total_pages,
             page: page[:number].to_i,
             members: members,
             years: years }

    render jsonapi: @datacenters, meta: meta, include: @include
  end

  # GET /datacenters/1
  def show
    render jsonapi: @datacenter
  end

  # POST /datacenters
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @datacenter = Datacenter.new(safe_params.except(:type))
      authorize! :create, @datacenter

      if @datacenter.save
        render jsonapi: @datacenter, status: :created, location: @datacenter
      else
        render jsonapi: serialize(@datacenter.errors), status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /datacenters/1
  def update
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @datacenter.update_attributes(safe_params.except(:type))
        render jsonapi: @datacenter
      else
        render json: serialize(@datacenter.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /datacenters/1
  def destroy
    @datacenter.destroy
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

  # Use callbacks to share common setup or constraints between actions.
  def set_datacenter
    @datacenter = Datacenter.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @datacenter.present?
  end

  private

  # Only allow a trusted parameter "white list" through.
  def safe_params
    attributes = [:uid, :name, :contact_email, :contact_name, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :password, :role_name, :version, :member_id]
    params.require(:data).permit(:id, :type, attributes: attributes)
  end

  # # Only allow a trusted parameter "white list" through.
  # def datacenter_params
  #   dc_params = ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
  #   allocator = Member.find_by(symbol: dc_params["member_id"])
  #   fail("member_id Not found") unless allocator.present?
  #   dc_params["allocator"] = allocator.id
  #   dc_params["password"] = encrypt_password(dc_params["password"])
  #   dc_params["symbol"] = dc_params["datacenter_id"]
  #   dc_params
  # end
end
