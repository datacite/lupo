class V2::EventsController < ApplicationController

  include Identifiable

  include Facetable

  prepend_before_action :authenticate_user_from_token!, :except => [:index, :show]
  before_action :load_event, only: [:show, :destroy]
  before_action :set_include, only: [:index, :show, :create, :update]
  authorize_resource only: [:destroy]

  def create
    @event = Event.where(subj_id: safe_params[:subj_id])
                  .where(obj_id: safe_params[:obj_id])
                  .where(source_id: safe_params[:source_id])
                  .where(relation_type_id: safe_params[:relation_type_id])
                  .first
    exists = @event.present?

    # create event if it doesn't exist already
    @event = Event.new(safe_params.except(:format)) unless @event.present?

    authorize! :create, @event

    if @event.update_attributes(safe_params)
      options = {}
      options[:is_collection] = false

      render json: V2::EventSerializer.new(@event, options).serialized_json, status: exists ? :ok : :created
    else
      errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def update
    @event = Event.where(uuid: params[:id]).first
    exists = @event.present?

    # create event if it doesn't exist already
    @event = Event.new(safe_params.except(:format)) unless @event.present?

    authorize! :update, @event

    if @event.update_attributes(safe_params)
      options = {}
      options[:is_collection] = false

      render json: V2::EventSerializer.new(@event, options).serialized_json, status: exists ? :ok : :created
    else
      errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: V2::EventSerializer.new(@event, options).serialized_json, status: :ok
  end

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "obj_id" then { "obj_id" => { order: 'asc' }}
           when "-obj_id" then { "obj_id" => { order: 'desc' }}
           when "total" then { "total" => { order: 'asc' }}
           when "-total" then { "total" => { order: 'desc' }}
           when "created" then { created_at: { order: 'asc' }}
           when "-created" then { created_at: { order: 'desc' }}
           when "updated" then { updated_at: { order: 'asc' }}
           when "-updated" then { updated_at: { order: 'desc' }}
           else { updated_at: { order: 'asc' }}
           end

    page = params[:page] || {}
    if page[:size].present?
      page[:size] = [page[:size].to_i, 1000].min
      max_number = 1
    else
      page[:size] = 1000
      max_number = 10000/page[:size]
    end
    page[:number] = page[:number].to_i > 0 ? [page[:number].to_i, max_number].min : 1

    if params[:id].present?
      response = Event.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Event.find_by_ids(params[:ids], page: page, sort: sort)
    else
      response = Event.query(params[:query],
                             subj_id: params[:subj_id],
                             obj_id: params[:obj_id],
                             doi: params[:doi],
                             orcid: params[:orcid],
                             prefix: params[:prefix],
                             subtype: params[:subtype],
                             citation_type: params[:citation_type],
                             source_id: params[:source_id],
                             registrant_id: params[:registrant_id],
                             relation_type_id: params[:relation_type_id],
                             issn: params[:issn],
                             publication_year: params[:publication_year],
                             occurred_at: params[:occurred_at],
                             year_month: params[:year_month],
                             page: page,
                             sort: sort)
    end

    total = response.results.total
    total_for_pages = page[:cursor].present? ? total.to_f : [total.to_f, 10000].min
    total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0

    sources = total > 0 ? facet_by_source(response.response.aggregations.sources.buckets) : nil
    prefixes = total > 0 ? facet_by_source(response.response.aggregations.prefixes.buckets) : nil
    citation_types = total > 0 ? facet_by_citation_type(response.response.aggregations.citation_types.buckets) : nil
    relation_types = total > 0 ? facet_by_relation_type(response.response.aggregations.relation_types.buckets) : nil
    registrants = total > 0  && params[:extra] ? facet_by_registrants(response.response.aggregations.registrants.buckets) : nil
    pairings = total > 0 && params[:extra] ? facet_by_pairings(response.response.aggregations.pairings.buckets) : nil
    dois = total > 0 && params[:extra] ? facet_by_dois(response.response.aggregations.dois.buckets) : nil
    dois_usage = total > 0 && params[:extra] ? facet_by_dois(response.response.aggregations.dois_usage.dois.buckets) : nil

    @events = response.results.results

    options = {}
    options[:meta] = {
      total: total,
      "totalPages" => total_pages,
      page: page[:cursor].blank? && page[:number].present? ? page[:number] : nil,
      sources: sources,
      prefixes: prefixes,
      "citationTypes" => citation_types,
      "relationTypes" => relation_types,
      pairings: pairings,
      registrants: registrants,
      "doisRelationTypes": dois,
      "doisUsageTypes": dois_usage
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @events.blank? ? nil : request.base_url + "/events?" + {
        "query" => params[:query],
        "subj-id" => params[:subj_id],
        "obj-id" => params[:obj_id],
        "doi" => params[:doi],
        "orcid" => params[:orcid],
        "prefix" => params[:prefix],
        "subtype" => params[:subtype],
        "citation_type" => params[:citation_type],
        "source-id" => params[:source_id],
        "relation-type-id" => params[:relation_type_id],
        "issn" => params[:issn],
        "registrant-id" => params[:registrant_id],
        "publication-year" => params[:publication_year],
        "year-month" => params[:year_month],
        "page[cursor]" => page[:cursor].present? ? Array.wrap(@events.to_a.last[:sort]).first : nil,
        "page[number]" => page[:cursor].blank? && page[:number].present? ? page[:number] + 1 : nil,
        "page[size]" => page[:size] }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: V2::EventSerializer.new(@events, options).serialized_json, status: :ok
  end

  def destroy
    if @event.destroy
      render json: { data: {} }, status: :ok
    else
      errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  protected

  def load_event
    response = Event.find_by_id(params[:id])
    @event = response.results.first
    fail ActiveRecord::RecordNotFound unless @event.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:subj, :obj]
    else
      @include = []
    end
  end

  private

  def safe_params
    nested_params = [:id, :name, { author: ["givenName", "familyName", :name] }, :funder, { funder: ["@id", "@type", :name] }, "alternateName", "proxyIdentifiers", { "proxyIdentifiers" => [] }, :publisher, :periodical, { periodical: [:type, :id, :name, :issn] }, "volumeNumber", "issueNumber", :pagination, :issn, "datePublished", "dateModified", "registrantId", :doi, :url, :type]
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, "messageAction", "sourceToken", :callback, "subjId", "objId", "relationTypeId", "sourceId", :total, :license, "occurredAt", :subj, :obj, subj: nested_params, obj: nested_params],
              keys: { id: :uuid }
    )
  end
end
