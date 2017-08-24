class DatacentersController < ApplicationController
  before_action :set_datacenter, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  serialization_scope :view_context

  # GET /datacenters
  def index
    options = {
      member_id: params["member-id"] }
    params[:query] ||= "*"
    response = Datacenter.search(params[:query], options)

    # pagination
    page = (params.dig(:page, :number) || 1).to_i
    per_page =(params.dig(:page, :size) || 25).to_i
    total = response.size
    total_pages = (total.to_f / per_page).ceil
    collection = response.page(page).per(per_page).order(created: :desc)

    years = nil
    years = response.map{|member| { id: member[:id],  year: member[:created].year }}.group_by { |d| d[:year] }.map{ |k, v| { id: k, title: k, count: v.count} }
    members = nil
    members = response.map{|member| { id: member[:id],  member_id: member[:member_id] }}.group_by { |d| d[:member_id] }.map{ |k, v| { id: k, title: k, count: v.count} }


    meta = { total: total,
             total_pages: total_pages,
             page: page,
             members: members,
             years: years
            }

    render jsonapi: collection, meta: meta
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

  private

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
