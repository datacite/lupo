class EventsController < ApplicationController
  include Identifiable

  include Facetable

  include BatchLoaderHelper
  require 'benchmark'

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
                             aggregations: params[:aggregations],
                             unique: params[:unique],
                             scroll_id: params[:scroll_id],
                             page: page,
                             sort: sort)
    end

    if page[:scroll].present?
      results = response.results
      total = response.total
    else
      total = response.results.total
      total_for_pages = page[:cursor].nil? ? [total.to_f, 10000].min : total.to_f
      total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0
    end

    if page[:scroll].present?
      options = {}
      options[:meta] = {
        total: total,
        "scroll-id" => response.scroll_id,
      }.compact
      options[:links] = {
        self: request.original_url,
        next: results.size < page[:size] || page[:size] == 0 ? nil : request.base_url + "/events?" + {
          "scroll-id" => response.scroll_id,
          "page[scroll]" => page[:scroll],
          "page[size]" => page[:size] }.compact.to_query
        }.compact
      options[:is_collection] = true

      render json: EventSerializer.new(results, options).serialized_json, status: :ok
    else
      aggregations = params.fetch(:aggregations, "") || ""

      sources = total.positive? && aggregations.blank? || aggregations.include?("query_aggregations") ? facet_by_source(response.response.aggregations.sources.buckets) : nil
      prefixes = total.positive? && aggregations.blank? || aggregations.include?("query_aggregations") ? facet_by_source(response.response.aggregations.prefixes.buckets) : nil
      citation_types = total.positive? && aggregations.blank? || aggregations.include?("query_aggregations") ? facet_by_citation_type(response.response.aggregations.citation_types.buckets) : nil
      relation_types = total.positive? && aggregations.blank? || aggregations.include?("query_aggregations") ? facet_by_relation_type(response.response.aggregations.relation_types.buckets) : nil
      registrants = total.positive? && aggregations.blank? || aggregations.include?("query_aggregations")  ? facet_by_registrants(response.response.aggregations.registrants.buckets) : nil
      pairings = total.positive? && aggregations.blank? || aggregations.include?("query_aggregations") ? facet_by_pairings(response.response.aggregations.pairings.buckets) : nil
      dois = total.positive? && aggregations.blank? || aggregations.include?("query_aggregations") ? facet_by_dois(response.response.aggregations.dois.buckets) : nil
      dois_usage = total.positive? ? EventsQuery.new.usage(params[:doi]) : nil
      # dois_citations = total.positive? && aggregations.blank? || aggregations.include?("query_aggregations") ? facet_citations_by_year_v1(response.response.aggregations.dois_citations) : nil
      citations = total.positive? ? EventsQuery.new.citations(params[:doi]) : nil
      citations_histogram = total.positive? ? EventsQuery.new.citations_histogram(params[:doi]) : nil
      references = total.positive? &&  aggregations.include?("citations_aggregations") ? facet_citations_by_dois(response.response.aggregations.references.dois.buckets) : nil
      relations = total.positive? &&  aggregations.include?("citations_aggregations") ? facet_citations_by_dois(response.response.aggregations.relations.dois.buckets) : nil

      views_histogram = total.positive? ? EventsQuery.new.views_histogram(params[:doi]) : nil
      downloads_histogram = total.positive? ? EventsQuery.new.downloads_histogram(params[:doi]) : nil

      # views = total.positive? ? EventsQuery.new.views(params[:doi]) : nil
      # downloads = total.positive? ? EventsQuery.new.downloads(params[:doi]) : nil
      unique_obj_count = total.positive? && aggregations.include?("advanced_aggregations") ? response.response.aggregations.unique_obj_count.value : nil
      unique_subj_count = total.positive? && aggregations.include?("advanced_aggregations") ? response.response.aggregations.unique_subj_count.value : nil
  
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
        # "doisCitations": dois_citations,
        "citationsHistogram": citations_histogram,
        "uniqueCitations": citations,
        "references": references,
        "relations": relations,
        "uniqueNodes": {
          "objCount": unique_obj_count,
          "subjCount": unique_subj_count
        },
        "viewsHistogram": views_histogram,
        # "views": views,
        "downloadsHistogram": downloads_histogram
        # "downloads": downloads
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

      options[:is_collection] = true
      
      events_serialized = EventSerializer.new(results, options).serializable_hash

      if @include.include?(:dois)
        options[:include] = []
        doi_names = (results.map { |event| event.doi}).uniq().join(",")
        events_serialized[:included] = DoiSerializer.new((Doi.find_by_id(doi_names).results), {is_collection: true}).serializable_hash.dig(:data) 
      end

      render json: events_serialized, status: :ok
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
