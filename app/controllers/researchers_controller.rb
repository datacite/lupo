class ResearchersController < ApplicationController
  include ActionController::MimeResponds

  prepend_before_action :authenticate_user!
  before_action :set_researcher, only: [:show, :destroy]
  load_and_authorize_resource except: [:index, :update]

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "name" then { "family_name.raw" => { order: 'asc' }}
           when "-name" then { "family_name.raw" => { order: 'desc' }}
           when "created" then { created_at: { order: 'asc' }}
           when "-created" then { created_at: { order: 'desc' }}
           else { "family_name.raw" => { order: 'asc' }}
           end

    page = page_from_params(params)

    if params[:id].present?
      response = Researcher.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Researcher.find_by_id(params[:ids], page: page, sort: sort)
    else
      response = Researcher.query(params[:query], page: page, sort: sort)
    end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number]
      }.compact

      options[:links] = {
        self: request.original_url,
        next: response.results.blank? ? nil : request.base_url + "/researchers?" + {
          query: params[:query],
          "page[number]" => page[:number] + 1,
          "page[size]" => page[:size],
          sort: params[:sort] }.compact.to_query
        }.compact
      options[:is_collection] = true

      fields = fields_from_params(params)
      if fields
        render json: ResearcherSerializer.new(response.results, options.merge(fields: fields)).serialized_json, status: :ok
      else
        render json: ResearcherSerializer.new(response.results, options).serialized_json, status: :ok
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Raven.capture_exception(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def show
    options = {}
    options[:is_collection] = false
    render json: ResearcherSerializer.new(@researcher, options).serialized_json, status: :ok
  end

  def create
    logger = Logger.new(STDOUT)
    @researcher = Researcher.new(safe_params)
    authorize! :create, @researcher

    if @researcher.save
      options = {}
      options[:is_collection] = false
      render json: ResearcherSerializer.new(@researcher, options).serialized_json, status: :created
    else
      logger.warn @researcher.errors.inspect
      render json: serialize_errors(@researcher.errors), status: :unprocessable_entity
    end
  end

  def update
    logger = Logger.new(STDOUT)
    @researcher = Researcher.where(uid: params[:id]).first
    exists = @researcher.present?

    # create researcher if it doesn't exist already
    @researcher = Researcher.new(safe_params.except(:format).merge(uid: params[:id])) unless @researcher.present?

    logger.info @researcher.inspect
    authorize! :update, @researcher

    if @researcher.update_attributes(safe_params)
      options = {}
      options[:is_collection] = false
      render json: ResearcherSerializer.new(@researcher, options).serialized_json, status: exists ? :ok : :created
    else
      logger.warn @researcher.errors.inspect
      render json: serialize_errors(@researcher.errors), status: :unprocessable_entity
    end
  end

  def destroy
    logger = Logger.new(STDOUT)
    if @researcher.destroy
      head :no_content
    else
      logger.warn @researcher.errors.inspect
      render json: serialize_errors(@researcher.errors), status: :unprocessable_entity
    end
  end

  protected

  def set_researcher
    @researcher = Researcher.where(uid: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @researcher.present?
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params,
      only: [
        :uid, :name, "givenNames", "familyName"
      ],
      keys: {
        id: :uid, "givenNames" => :given_names, "familyName" => :family_name
      }
    )
  end
end
