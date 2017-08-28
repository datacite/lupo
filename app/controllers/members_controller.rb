class MembersController < ApplicationController
  before_action :set_member, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  serialization_scope :view_context

  # GET /members
  def index
    # options = {
    #   member_type: params["member-type"],
    #   region: params[:region],
    #   year: params[:year] }
    options = { }
    params[:query] ||= "*"
    response = Member.search(params[:query], options)


    # pagination
    page = (params.dig(:page, :number) || 1).to_i
    per_page =(params.dig(:page, :size) || 25).to_i
    total = response[:response].size
    total_pages = (total.to_f / per_page).ceil
    collection = response[:response].page(page).per(per_page).order(created: :desc).to_a

    meta = { total: total,
             total_pages: total_pages,
             page: page,
             regions: response[:regions],
             member_types: response[:member_types],
             years: response[:years]
            }

    render jsonapi: collection, meta: meta
  end

  # GET /members/1
  def show
      render jsonapi: @member, include:['datacenters', 'prefixes']
  end

  # POST /members
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render jsonapi: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @member = Member.new(safe_params.except(:type))
      authorize! :create, @member

      if @member.save
        render jsonapi: @member, status: :created, location: @member
      else
        render jsonapi: serialize(@member.errors), status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /members/1
  def update
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render jsonapi: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @member.update_attributes(safe_params.except(:type))
        render jsonapi: @member
      else
        render jsonapi: serialize(@member.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /members/1
  def destroy
    @member.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_member
    @member = Member.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @member.present?
  end

  private

  # Only allow a trusted parameter "white list" through.
  def safe_params
    attributes = [:uid, :name, :contact_email, :contact_name, :description, :year, :region, :country_code, :website, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :password, :role_name, :member_id, :version]
    # ActiveModelSerializers::Deserialization.jsonapi_parse!(params.to_unsafe_h)[:prefixes_ids]
    relationships = [:relationships, :prefixes]
    params.require(:data).permit(:id, :type, attributes: attributes, prefixes_attributes: relationships)

  end

  # Only allow a trusted parameter "white list" through.
  # def member_params
  #   params.require(:data)
  #     .require(:attributes)
  #     .permit(:uid, :name, :contact_email, :contact_name, :description, :year, :region, :country_code, :website, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :password, :role_name, :member_id, :version)
  #
  #   mb_params= ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
  #   mb_params["password"] = encrypt_password(mb_params["password"])
  #   mb_params
  # end
end
