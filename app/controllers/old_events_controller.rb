# frozen_string_literal: true

class OldEventsController < ApplicationController
  include ActionController::MimeResponds

  include Identifiable

  include Facetable

  prepend_before_action :authenticate_user!, except: %i[index show]
  before_action :detect_crawler
  before_action :load_event, only: %i[show]
  before_action :set_include, only: %i[index show create update]
  authorize_resource only: %i[destroy]

  def create
    @event =
      Event.where(subj_id: safe_params[:subj_id]).where(
        obj_id: safe_params[:obj_id],
      ).
        where(source_id: safe_params[:source_id]).
        where(relation_type_id: safe_params[:relation_type_id]).
        first
    exists = @event.present?

    # create event if it doesn't exist already
    @event = Event.new(safe_params.except(:format)) if @event.blank?

    authorize! :create, @event

    if @event.update(safe_params)
      options = {}
      options[:is_collection] = false

      render(
        json: OldEventSerializer.new(@event, options).serializable_hash.to_json,
        status: exists ? :ok : :created)
    else
      errors =
        @event.errors.full_messages.map do |message|
          { status: 422, title: message }
        end
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def update
    @event = Event.where(uuid: params[:id]).first
    exists = @event.present?

    # create event if it doesn't exist already
    @event = Event.new(safe_params.except(:format)) if @event.blank?

    authorize! :update, @event

    if @event.update(safe_params)
      options = {}
      options[:is_collection] = false

      render(
        json: OldEventSerializer.new(@event, options).serializable_hash.to_json,
        status: exists ? :ok : :created
      )
    else
      errors =
        @event.errors.full_messages.map do |message|
          { status: 422, title: message }
        end
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def show
    options = {}
    options[:is_collection] = false

    render(
      json: OldEventSerializer.new(@event, options).serializable_hash.to_json,
      status: :ok
    )
  end

  def index
    sort =
      case params[:sort]
      when "relevance"
        { "_score" => { order: "desc" } }
      when "obj_id"
        { "obj_id" => { order: "asc" } }
      when "-obj_id"
        { "obj_id" => { order: "desc" } }
      when "total"
        { "total" => { order: "asc" } }
      when "-total"
        { "total" => { order: "desc" } }
      when "created"
        { created_at: { order: "asc" } }
      when "-created"
        { created_at: { order: "desc" } }
      when "updated"
        { updated_at: { order: "asc" } }
      when "relation_type_id"
        { relation_type_id: { order: "asc" } }
      when "-updated"
        { updated_at: { order: "desc" } }
      else
        { updated_at: { order: "asc" } }
      end

    page = page_from_params(params)

    response = if params[:id].present?
      Event.find_by_id(params[:id])
    elsif params[:ids].present?
      Event.find_by_ids(params[:ids], page: page, sort: sort)
    else
      Event.query(
        params[:query],
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
        occurred_at: params[:occurred_at],
        publication_year: params[:publication_year],
        year_month: params[:year_month],
        scroll_id: params[:scroll_id],
        page: page,
        sort: sort,
      )
    end

    if page[:scroll].present?
      results = response.results
      total = response.total
    else
      total = response.results.total
      total_for_pages =
        page[:cursor].nil? ? total.to_f : [total.to_f, 10_000].min
      total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0
    end

    if page[:scroll].present?
      options = {}
      options[:meta] = {
        total: total, "scroll-id" => response.scroll_id
      }.compact
      options[:links] = {
        self: request.original_url,
        next:
          if results.size < page[:size] || page[:size] == 0
            nil
          else
            request.base_url + "/events?" +
              {
                "scroll-id" => response.scroll_id,
                "page[scroll]" => page[:scroll],
                "page[size]" => page[:size],
              }.compact.
              to_query
          end,
      }.compact
      options[:is_collection] = true

      render(
        json: OldEventSerializer.new(results, options)..serializable_hash.to_json,
        status: :ok
      )
    else
      results = response.results

      respond_to do |format|
        format.json do
          sources =
            total > 0 ? facet_by_source(response.aggregations.sources.buckets) : nil
          prefixes =
            if total > 0
              facet_by_source(response.aggregations.prefixes.buckets)
            end
          occurred =
            if total > 0
              facet_by_year(response.aggregations.occurred.buckets)
            end
          citation_types =
            if total > 0
              facet_by_citation_type_v1(
                response.aggregations.citation_types.buckets,
              )
            end
          relation_types =
            if total > 0
              facet_by_relation_type_v1(
                response.aggregations.relation_types.buckets,
              )
            end
          registrants =
            if total > 0
              facet_by_registrants(response.aggregations.registrants.buckets)
            end
          options = {}
          options[:meta] = {
            total: total,
            "total-pages" => total_pages,
            page:
              page[:cursor].nil? && page[:number].present? ? page[:number] : nil,
            sources: sources,
            occurred: occurred,
            prefixes: prefixes,
            "citation-types" => citation_types,
            "relation-types" => relation_types,
            registrants: registrants,
          }.compact

          options[:links] = {
            self: request.original_url,
            next:
              if results.size < page[:size]
                nil
              else
                request.base_url + "/events?" +
                  {
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
                    "page[cursor]" => page[:cursor] ? make_cursor(results) : nil,
                    "page[number]" =>
                      if page[:cursor].nil? && page[:number].present?
                        page[:number] + 1
                      end,
                    "page[size]" => page[:size],
                  }.compact.
                  to_query
              end,
          }.compact
          options[:is_collection] = true

          render(
            json: OldEventSerializer.new(results, options).serializable_hash.to_json,
            status: :ok
          )
        end
        format.csv do
          headers = %w[
            subj-id
            obj-id
            source-id
            relation-type-id
            occurred_at
          ]

          rows = results.to_a.map do |event|
            CSV.generate_line([event.subj_id, event.obj_id, event.source_id, event.relation_type_id, event.occurred_at])
          end

          csv = [CSV.generate_line(headers)] + rows
          filename = "events-#{Date.today}.csv"
          send_data csv, filename: filename
        end
      end
    end
  end

  def destroy
    @event = Event.where(uuid: params[:id]).first
    if @event.destroy
      head :no_content
    else
      errors =
        @event.errors.full_messages.map do |message|
          { status: 422, title: message }
        end
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  protected
    def load_event
      response = Event.find_by_id(params[:id])
      @event = response.results.first
      fail ActiveRecord::RecordNotFound if @event.blank?
    end

    def set_include
      if params[:include].present?
        @include =
          params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
        @include = @include & %i[subj obj]
      else
        @include = []
      end
    end

  private
    def safe_params
      nested_params = [
        :id,
        :name,
        { author: ["given-name", "family-name", :name] },
        "alternate-name",
        :publisher,
        "provider-id",
        :periodical,
        "volume-number",
        "issue-number",
        :pagination,
        :issn,
        "date-published",
        "registrant-id",
        :doi,
        :url,
        :type,
      ]
      ActiveModelSerializers::Deserialization.jsonapi_parse!(
        params,
        only: [
          :id,
          "message-action",
          "source-token",
          :callback,
          "subj-id",
          "obj-id",
          "relation-type-id",
          "source-id",
          :total,
          :license,
          "occurred-at",
          :subj,
          :obj,
          { subj: nested_params, obj: nested_params },
        ],
        keys: { id: :uuid },
      )
    end
end
