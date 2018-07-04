require 'uri'

class DoisController < ApplicationController
  prepend_before_action :authenticate_user!
  before_action :set_doi, only: [:show, :destroy, :get_url]
  before_action :set_include, only: [:index, :show, :create, :update]
  authorize_resource :except => [:index, :show, :random]

  before_bugsnag_notify :add_metadata_to_bugsnag

  def index
    # support nested routes
    if params[:client_id].present?
      client = Client.where('datacentre.symbol = ?', params[:client_id]).first
      collection = client.present? ? client.dois : Doi.none
      total = client.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    elsif params[:provider_id].present? && params[:provider_id] != "admin"
      provider = Provider.where('allocator.symbol = ?', params[:provider_id]).first
      collection = provider.present? ? Doi.joins(:client).where("datacentre.allocator = ?", provider.id) : Doi.none
      total = provider.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    elsif params[:id].present?
      collection = Doi.where(doi: params[:id])
      total = collection.all.size
    else
      provider = Provider.unscoped.where('allocator.symbol = ?', "ADMIN").first
      total = provider.present? ? provider.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i } : 0
      collection = Doi
    end

    if params[:query].present?
      collection = Doi.query(params[:query])
      total = collection.all.size
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total_pages = (total.to_f / page[:size]).ceil

    order = case params[:sort]
            when "name" then "dataset.doi"
            when "-name" then "dataset.doi DESC"
            when "created" then "dataset.created"
            else "dataset.created DESC"
            end

    @dois = collection.order(order).page(page[:number]).per(page[:size]).without_count

    meta = { total: total,
             total_pages: total_pages,
             page: page[:number].to_i }

    render jsonapi: @dois, meta: meta, include: @include, each_serializer: DoiSerializer
  end

  def show
    render jsonapi: @doi, include: @include, serializer: DoiSerializer
  end

  def validate
    # Rails.logger.info safe_params.inspect
    @doi = Doi.new(safe_params)
    authorize! :create, @doi

    if @doi.errors.present?
      Rails.logger.info @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), status: :ok
    elsif @doi.validation_errors?
      Rails.logger.info @doi.validation_errors.inspect
      render jsonapi: serialize(@doi.validation_errors), status: :ok
    else
      render jsonapi: @doi, serializer: DoiSerializer
    end
  end

  def create
   #  Rails.logger.info safe_params.inspect
    @doi = Doi.new(safe_params.merge(event: safe_params[:event] || "start"))
    authorize! :create, @doi

    # capture username and password for reuse in the handle system
    @doi.current_user = current_user

    if safe_params[:xml] && @doi.aasm_state != "draft" && @doi.validation_errors?
      Rails.logger.error @doi.validation_errors.inspect
      render jsonapi: serialize(@doi.validation_errors), status: :unprocessable_entity
    elsif @doi.save
      render jsonapi: @doi, status: :created, location: @doi
    else
      Rails.logger.warn @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), include: @include, status: :unprocessable_entity
    end
  end

  def update
    #  Rails.logger.info safe_params.inspect
    @doi = Doi.where(doi: params[:id]).first
    exists = @doi.present?

    if exists
      @doi.assign_attributes(safe_params.except(:doi))
    else
      doi_id = validate_doi(params[:id])
      @doi = Doi.new(safe_params.merge(doi: doi_id, event: safe_params[:event] || "start"))
    end

    authorize! :update, @doi

    # capture username and password for reuse in the handle system
    @doi.current_user = current_user

    if safe_params[:xml] && @doi.aasm_state != "draft" && @doi.validation_errors?
      Rails.logger.error @doi.validation_errors.inspect
      render jsonapi: serialize(@doi.validation_errors), status: :unprocessable_entity
    elsif @doi.save
      render jsonapi: @doi, status: exists ? :ok : :created
    else
      Rails.logger.warn @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), include: @include, status: :unprocessable_entity
    end
  end

  def destroy
    if @doi.draft?
      if @doi.destroy
        head :no_content
      else
        Rails.logger.warn @doi.errors.inspect
        render jsonapi: serialize(@doi.errors), status: :unprocessable_entity
      end
    else
      response.headers["Allow"] = "HEAD, GET, POST, PATCH, PUT, OPTIONS"
      render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
    end
  end

  def status
    doi = Doi.where(doi: params[:id]).first
    status = Doi.get_landing_page_info(doi: doi, url: params[:url])
    render json: status.to_json, status: :ok
  end

  def random
    prefix = params[:prefix].presence || "10.5072"
    doi = generate_random_doi(prefix, number: params[:number])

    render json: { doi: doi }.to_json
  end

  def set_state
    authorize! :update, Doi
    Doi.set_state
    render json: { message: "DOI state updated." }.to_json, status: :ok
  end

  def get_url
    authorize! :update, Doi

    if @doi.aasm_state == "draft"
      url = @doi.url
      response = OpenStruct.new(status: 404, body: { "errors" => [{ "title" => "No URL found." }] })
    else
      response = @doi.get_url(username: current_user.uid.upcase, password: current_user.password)
      url = response.body["data"]
    end

    if url.present?
      render json: { url: url }.to_json, status: :ok
    else
      render json: response.body.to_json, status: response.status || :bad_request
    end
  end

  def get_dois
    authorize! :update, Doi

    response = Doi.get_dois(username: current_user.uid.upcase, password: current_user.password)
    if response.status == 200
      render json: { dois: response.body["data"].split("\n") }.to_json, status: :ok
    elsif response.status == 204
      head :no_content
    else
      render json: serialize(response.body["errors"]), status: :bad_request
    end
  end

  def set_minted
    authorize! :update, Doi
    Doi.set_minted
    render json: { message: "DOI minted timestamp added." }.to_json, status: :ok
  end

  def set_url
    authorize! :update, Doi
    from_date = Time.zone.now - 1.day
    Doi.where(url: nil).where(aasm_state: ["registered", "findable"]).where("updated >= ?", from_date).find_each do |doi|
      UrlJob.perform_later(doi)
    end
    render json: { message: "Adding missing URLs queued." }.to_json, status: :ok
  end

  def delete_test_dois
    authorize! :delete, Doi
    Doi.delete_test_dois
    render json: { message: "Test DOIs deleted." }.to_json, status: :ok
  end

  protected

  def set_doi
    @doi = Doi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?

    # capture username and password for reuse in the handle system
    @doi.current_user = current_user
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ["client,provider,resource_type"]
    end
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    attributes = [:doi, "confirm-doi", :identifier, :url, :title, :publisher, :published, :prefix, :suffix, "resource-type-subtype", "last-landing-page", "last-landing-page-status", "last-landing-page-status-check", "last-landing-page-content-type", :description, :license, :xml, :version, "metadata-version", "schema-version", :state, "is-active", :reason, :registered, :updated, :mode, :event, :regenerate, :client, "resource_type", author: [:type, :id, :name, "given-name", "family-name"]]
    relationships = [{ client: [data: [:type, :id]] },  { provider: [data: [:type, :id]] }, { "resource-type" => [:data, data: [:type, :id]] }]
    p = params.require(:data).permit(:type, :id, attributes: attributes, relationships: relationships)
    p = p.fetch("attributes").merge(client_id: p.dig("relationships", "client", "data", "id"), resource_type_general: camelize_str(p.dig("relationships", "resource-type", "data", "id")))
    p.merge(
      additional_type: p["resource-type-subtype"],
      schema_version: p["schema-version"],
      last_landing_page: p["last-landing-page"],
      last_landing_page_status: p["last-landing-page-status"],
      last_landing_page_status_check: p["last-landing-page-status-check"],
      last_landing_page_content_type: p["last-landing-page-content-type"]
    ).except("confirm-doi", :identifier, :prefix, :suffix, "resource-type-subtype", "metadata-version", "schema-version", :state, "is-active", :registered, :updated, :mode, "last-landing-page", "last-landing-page-status", "last-landing-page-status-check", "last-landing-page-content-type")
  end

  def underscore_str(str)
    return str unless str.present?

    str.underscore
  end

  def camelize_str(str)
    return str unless str.present?

    str.underscore.camelize
  end

  def add_metadata_to_bugsnag(report)
    return nil unless params.dig(:data, :attributes, :xml).present?

    report.add_tab(:metadata, {
      metadata: Base64.decode64(params.dig(:data, :attributes, :xml))
    })
  end
end
