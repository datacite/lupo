class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  # GET /prefixes
  def index
    collection = Prefix

    if params[:id].present?
      collection = collection.where(prefix: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    # cache providers for faster queries
    if params["provider-id"].present?
      provider = cached_provider_response(params["provider-id"].upcase)
      collection = collection.includes(:providers).where('allocator.id' => provider.id)
    end

    if params["client-id"].present?
      client = cached_client_response(params["client-id"].upcase)
      collection = collection.includes(:clients).where('datacentre.id' => client.id)
    end

    collection = collection.where('YEAR(prefix.created) = ?', params[:year]) if params[:year].present?

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(prefix.created) = ?', params[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(prefix.created) DESC").group("YEAR(prefix.created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    # calculate facet counts after filtering
    # no faceting by client
    if params["provider-id"].present?
      providers = [{ id: params["provider-id"],
                   title: provider.name,
                   count: collection.includes(:providers).where('allocator.id' => provider.id).count }]
    else
      providers = collection.includes(:providers).where.not('allocator.id' => nil).group('allocator.id').count
      providers = providers
                  .sort { |a, b| b[1] <=> a[1] }
                  .map do |i|
                         provider = cached_providers.find { |m| m.id == i[0] }
                         { id: provider.symbol.downcase, title: provider.name, count: i[1] }
                       end
    end

    # pagination
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @prefixes = collection.order(created: :desc).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @prefixes.total_pages,
             page: page[:number].to_i,
             providers: providers,
             years: years }

    render jsonapi: @prefixes, meta: meta, include: @include
  end

  # GET /prefixes/1
  def show
    render jsonapi: @prefix, include: @include, serializer: PrefixSerializer
  end

  # POST /prefixes
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @prefix = Prefix.new(safe_params.except(:type))
      authorize! :create, @prefix

      if @prefix.save
        render jsonapi: @prefix, status: :created, location: @prefix
      else
        render jsonapi: serialize(@prefix.errors), status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /prefixes/1
  def update
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @prefix.update_attributes(safe_params.except(:type))
        render jsonapi: @prefix
      else
        render json: serialize(@prefix.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /prefixes/1
  def destroy
    @prefix.destroy
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      # always include because Ember pagination doesn't (yet) understand include parameter
      @include = ['clients','providers']
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_prefix
    @prefix = Prefix.where(prefix: params[:id]).first

    # fallback to call handle server, i.e. for prefixes not from DataCite
    @prefix = Handle.where(id: params[:id]) unless @prefix.present?
    Rails.logger.info @prefix.inspect
    fail ActiveRecord::RecordNotFound unless @prefix.present?
  end

  def safe_params
    attributes = [:uid, :prefix, :version]
    params.require(:data).permit(:id, :type, attributes: attributes)
  end
  # Only allow a trusted parameter "white list" through.
  # def prefix_params
  #   params.require(:data)
  #     .require(:attributes)
  #     .permit(:created, :prefix, :version)
  #   pf_params = ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
  #   pf_params
  # end
end
