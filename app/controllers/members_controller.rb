class MembersController < ApplicationController
  before_action :set_member, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  def index
    collection = Member

    if params[:id].present?
      collection = collection.where(symbol: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    collection = collection.where(member_type: params['member-type']) if params['member-type'].present?
    collection = collection.where(region: params[:region]) if params[:region].present?
    collection = collection.where(year: params[:year]) if params[:year].present?

    # calculate facet counts after filtering
    if params["member-type"].present?
      member_types = [{ id: params["member-type"],
                        title: params["member-type"].humanize,
                        count: collection.where(member_type: params["member-type"]).count }]
    else
      member_types = collection.where.not(member_type: nil).group(:member_type).count
      member_types = member_types.map { |k,v| { id: k, title: k.humanize, count: v } }
    end
    if params[:region].present?
      regions = [{ id: params[:region],
                   title: REGIONS[params[:region].upcase],
                   count: collection.where(region: params[:region]).count }]
    else
      regions = collection.where.not(region: nil).group(:region).count
      regions = regions.map { |k,v| { id: k.downcase, title: REGIONS[k], count: v } }
    end
    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where(year: params[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(created) DESC").group("YEAR(created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @members = collection.order(:name).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @members.total_pages,
             page: page[:number].to_i,
             member_types: member_types,
             regions: regions,
             years: years }

    render jsonapi: @members, meta: meta, include: @include
  end

  def show
    render jsonapi: @member
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

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = nil
    end
  end

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
