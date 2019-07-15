require 'benchmark'

class EventsController < ApplicationController
  include Identifiable

  include Facetable

  include BatchLoaderHelper


  prepend_before_action :authenticate_user!, except: [:index, :show]
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

      render json: EventSerializer.new(@event, options).serialized_json, status: exists ? :ok : :created
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

      render json: EventSerializer.new(@event, options).serialized_json, status: exists ? :ok : :created
    else
      errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: EventSerializer.new(@event, options).serialized_json, status: :ok
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
           when "relation_type_id" then { relation_type_id: { order: 'asc' }}
           else { updated_at: { order: 'asc' }}
           end

    page = page_from_params(params)

    logger = Logger.new(STDOUT)

    if params[:id].present?
      response = Event.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Event.find_by_id(params[:ids], page: page, sort: sort)
    else
      response = Event.query(params[:query],
                             subj_id: params[:subj_id],
                             obj_id: params[:obj_id],
                             doi: params[:doi_id] || params[:doi],
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
                             unique: params[:unique],
                             page: page,
                             sort: sort)
    end

    total = response.results.total
    total_for_pages = page[:cursor].nil? ? total.to_f : [total.to_f, 10000].min
    total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0

    sources = total.positive? ? facet_by_source(response.response.aggregations.sources.buckets) : nil
    prefixes = total.positive? ? facet_by_source(response.response.aggregations.prefixes.buckets) : nil
    citation_types = total.positive? ? facet_by_citation_type(response.response.aggregations.citation_types.buckets) : nil
    relation_types = total.positive? ? facet_by_relation_type(response.response.aggregations.relation_types.buckets) : nil
    registrants = total.positive? && params[:extra] ? facet_by_registrants(response.response.aggregations.registrants.buckets) : nil
    pairings = total.positive? && params[:extra] ? facet_by_pairings(response.response.aggregations.pairings.buckets) : nil
    dois = total.positive? && params[:extra] ? facet_by_dois(response.response.aggregations.dois.buckets) : nil
    dois_usage = total.positive? && params[:extra] ? facet_by_dois(response.response.aggregations.dois_usage.dois.buckets) : nil
    dois_citations = total.positive? && params[:extra] ? facet_citations_by_year(response.response.aggregations.dois_citations) : nil
    # unique_citations = total.positive? && params[:extra] ? facet_citations_by_dois(response.response.aggregations.unique_citations.dois.buckets) : nil
 
    results = response.results

    options = {}
    options[:meta] = {
      total: total,
      "totalPages" => total_pages,
      page: page[:cursor].nil? && page[:number].present? ? page[:number] : nil,
      sources: sources,
      prefixes: prefixes,
      "citationTypes" => citation_types,
      "relationTypes" => relation_types,
      pairings: pairings,
      registrants: registrants,
      "doisRelationTypes": dois,
      "doisUsageTypes": dois_usage,
      "doisCitations": dois_citations,
      # "uniqueCitations": unique_citations
    }.compact

    options[:links] = {
      self: request.original_url,
      next: results.size < page[:size] || page[:size] == 0 ? nil : request.base_url + "/events?" + {
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
        "page[cursor]" => page[:cursor] ? Base64.urlsafe_encode64(Array.wrap(results.to_a.last[:sort]).join(","), padding: false) : nil,
        "page[number]" => page[:cursor].nil? && page[:number].present? ? page[:number] + 1 : nil,
        "page[size]" => page[:size] }.compact.to_query
      }.compact

    options[:include] = [] if @include.include? :dois
    options[:is_collection] = true
    
    bmr = Benchmark.ms {

      ##### Batchloading doi metadata
      ### Unfotunately fast_json fetches relations by item and one cannot pass and the includes
      ### We obtain all the events' dois, we batchload them and serilize them 
      ### Then we serlize all the events and we merged them both together
      events_serialized = EventSerializer.new(results, options).serializable_hash

      # doi_names = (results.map { |event| event.doi}).join(",").split(",").uniq.join(",")

      if @include.include? :dois
        # doi_names = (results.map { |event| event.doi}).join(",")
        doi_names = "10.18711/0jdfnq2c,10.14288/1.0043659,10.25620/iciber.issn.1476-4687"
        events_serialized[:included] = if params["batchload"] == "true" || params["batchload"].nil?
          logger.info "batchload"
          DoiSerializer.new(load_doi(doi_names), {is_collection: true}).serializable_hash.dig(:data) 
        elsif params["batchload"] == "false"
          logger.info "find_by_doi"
          Doi.find_by_id(doi_names).results
        end
      end

      render json: events_serialized, status: :ok
    }

    if bmr > 3000
      logger.warn "[Benchmark Warning] Events render. batchload: #{params['batchload']} " + bmr.to_s + " ms"
    else
      logger.info "[Benchmark] Events render. batchload: #{params['batchload']} " + bmr.to_s + " ms"
    end
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
      @include &= [:dois]
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
