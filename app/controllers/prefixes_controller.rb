class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  # GET /prefixes
  def index
    # support nested routes
    if params[:id].present?
      collection = Prefix.where(prefix: params[:id])
    elsif params[:provider_id].present?
      provider = Provider.where('allocator.symbol = ?', params[:provider_id]).first
      collection = provider.present? ? provider.prefixes : Prefix.none
    elsif params[:client_id].present?
      client = Client.where('datacentre.symbol = ?', params[:client_id]).first
      collection = client.present? ? client.prefixes : Prefix.none
    else
      collection = Prefix
    end

    collection = collection.state(params[:state]) if params[:state].present?
    collection = collection.query(params[:query]) if params[:query].present?
    collection = collection.where('YEAR(prefix.created) = ?', params[:year]) if params[:year].present?

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(prefix.created) = ?', params[:year]).count }]
    else
      years = collection.where.not(prefix: nil).order("prefix.created DESC").group("YEAR(prefix.created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    # calculate facet counts after filtering
    # no faceting by client
    if params[:provider_id].present?
      providers = [{ id: params[:provider_id],
                   title: provider.name,
                   count: collection.includes(:providers).where('allocator.id' => provider.id).count }]
    else
      providers = collection.includes(:providers).where.not('allocator.id' => nil).group('allocator.id').count
      providers = providers
                  .sort { |a, b| b[1] <=> a[1] }
                  .reduce([]) do |sum, i|
                                if provider = cached_providers.find { |m| m.id == i[0] }
                                  sum << { id: provider.symbol.downcase, title: provider.name, count: i[1] }
                                end

                                sum
                              end
    end

    if params[:state].present?
      states = [{ id: params[:state],
                  title: params[:state].underscore.humanize,
                  count: collection.count }]
    else
      states = [{ id: "unassigned",
                  title: "Unassigned",
                  count: collection.state("unassigned").count },
                { id: "without-client",
                  title: "Without client",
                  count: collection.state("without-client").count },
                { id: "with-client",
                  title: "With client",
                  count: collection.state("with-client").count }]
    end

    # pagination
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    order = case params[:sort]
            when "name" then "prefix.prefix"
            when "-name" then "prefix.prefix DESC"
            when "created" then "prefix.created"
            else "prefix.created DESC"
            end

    @prefixes = collection.order(order).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @prefixes.total_pages,
             page: page[:number].to_i,
             states: states,
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
    @prefix = Prefix.new(safe_params)
    authorize! :create, @prefix

    if @prefix.save
      render jsonapi: @prefix, status: :created, location: @prefix
    else
      Rails.logger.warn @prefix.errors.inspect
      render jsonapi: serialize(@prefix.errors), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /prefixes/1
  def update
    if @prefix.update_attributes(safe_params)
      render jsonapi: @prefix
    else
      Rails.logger.warn @prefix.errors.inspect
      render json: serialize(@prefix.errors), status: :unprocessable_entity
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
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :clients, :providers, :created],
              keys: { id: :prefix }
    )
  end
end
