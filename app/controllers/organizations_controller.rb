# frozen_string_literal: true

class OrganizationsController < ApplicationController
  include ActionController::MimeResponds
  include Countable

  before_action :set_provider, only: %i[show]

  def index
    sort =
      case params[:sort]
      when "relevance"
        { "_score" => { order: "desc" } }
      when "name"
        { "name.raw" => { order: "asc" } }
      when "-name"
        { "name.raw" => { order: "desc" } }
      when "created"
        { created: { order: "asc" } }
      when "-created"
        { created: { order: "desc" } }
      else
        { "name.raw" => { order: "asc" } }
      end

    page = page_from_params(params)

    response = if params[:id].present?
      Provider.find_by_id(params[:id])
    elsif params[:ids].present?
      Provider.find_by_id(params[:ids], page: page, sort: sort)
    else
      Provider.query(
        params[:query],
        year: params[:year],
        from_date: params[:from_date],
        until_date: params[:until_date],
        region: params[:region],
        consortium_id: params[:provider_id],
        organization_type: params[:organization_type],
        focus_area: params[:focus_area],
        page: page,
        sort: sort,
      )
    end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      years =
        if total > 0
          facet_by_year(response.response.aggregations.years.buckets)
        end
      regions =
        if total > 0
          facet_by_region(response.response.aggregations.regions.buckets)
        end
      member_types =
        if total > 0
          facet_by_key(response.response.aggregations.member_types.buckets)
        end
      organization_types =
        if total > 0
          facet_by_key(
            response.response.aggregations.organization_types.buckets,
          )
        end
      focus_areas =
        if total > 0
          facet_by_key(response.response.aggregations.focus_areas.buckets)
        end

      @providers = response.results
      respond_to do |format|
        format.json do
          options = {}
          options[:meta] = {
            total: total,
            "totalPages" => total_pages,
            page: page[:number],
            years: years,
            regions: regions,
            "memberTypes" => member_types,
            "organizationTypes" => organization_types,
            "focusAreas" => focus_areas,
          }.compact

          options[:links] = {
            self: request.original_url,
            next:
              if @providers.blank? || page[:number] == total_pages
                nil
              else
                request.base_url + "/providers?" +
                  {
                    query: params[:query],
                    year: params[:year],
                    region: params[:region],
                    "member_type" => params[:member_type],
                    "organization_type" => params[:organization_type],
                    "focus-area" => params[:focus_area],
                    "page[number]" => page[:number] + 1,
                    "page[size]" => page[:size],
                    sort: sort,
                    fields: fields_hash_from_params(params)
                  }.compact.
                  to_query
              end,
          }.compact
          options[:include] = @include
          options[:is_collection] = true
          options[:params] = { current_ability: current_ability }

          fields = fields_from_params(params)
          if fields
            render(
              json: ProviderSerializer.new(@providers, options.merge(fields: fields)).serializable_hash.to_json,
              status: :ok
            )
          else
            render(
              json: ProviderSerializer.new(@providers, options).serializable_hash.to_json,
              status: :ok
            )
          end
        end
        header = %w[
          accountName
          fabricaAccountId
          parentFabricaAccountId
          salesForceId
          parentSalesForceId
          memberType
          isActive
          accountDescription
          accountWebsite
          region
          country
          logoUrl
          focusArea
          organisationType
          accountType
          generalContactEmail
          groupEmail
          technicalContactEmail
          technicalContactGivenName
          technicalContactFamilyName
          secondaryTechnicalContactEmail
          secondaryTechnicalContactGivenName
          secondaryTechnicalContactFamilyName
          serviceContactEmail
          serviceContactGivenName
          serviceContactFamilyName
          secondaryServiceContactEmail
          secondaryServiceContactGivenName
          secondaryServiceContactFamilyName
          votingContactEmail
          votingContactGivenName
          votingContactFamilyName
          billingStreet
          billingPostalCode
          billingCity
          department
          billingOrganization
          billingState
          billingCountry
          billingContactEmail
          billingContactGivenName
          billingontactFamilyName
          secondaryBillingContactEmail
          secondaryBillingContactGivenName
          secondaryBillingContactFamilyName
          twitter
          rorId
          created
          updated
          deletedAt
        ]
        format.csv do
          render request.format.to_sym => response.records.to_a, header: header
        end
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      Raven.capture_exception(e)

      message =
        JSON.parse(e.message[6..-1]).to_h.dig(
          "error",
          "root_cause",
          0,
          "reason",
        )

      render json: { "errors" => { "title" => message } }.to_json,
             status: :bad_request
    end
  end

  def show
    options = {}
    options[:meta] = {
      repositories:
        client_count(provider_id: params[:id] == "admin" ? nil : params[:id]),
      dois: doi_count(provider_id: params[:id] == "admin" ? nil : params[:id]),
    }.compact
    options[:include] = @include
    options[:is_collection] = false
    options[:params] = { current_ability: current_ability }

    render(
      json: ProviderSerializer.new(@provider, options).serializable_hash.to_json,
      status: :ok
    )
  end

  protected
    def set_provider
      @provider =
        Provider.unscoped.where(
          "allocator.role_name IN ('ROLE_FOR_PROFIT_PROVIDER', 'ROLE_CONTRACTUAL_PROVIDER', 'ROLE_CONSORTIUM' , 'ROLE_CONSORTIUM_ORGANIZATION', 'ROLE_ALLOCATOR', 'ROLE_ADMIN', 'ROLE_MEMBER', 'ROLE_DEV')",
        ).
          where(deleted_at: nil).
          where(symbol: params[:id]).
          first
      fail ActiveRecord::RecordNotFound if @provider.blank?
    end
end
