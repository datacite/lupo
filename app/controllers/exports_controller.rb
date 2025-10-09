# frozen_string_literal: true

class ExportsController < ApplicationController
  include ActionController::MimeResponds

  before_action :authenticate_user_with_basic_auth!

  MEMBER_TYPES = {
    "consortium" => "Consortium",
    "consortium_organization" => "Consortium Organization",
    "direct_member" => "Direct Member",
    "member_only" => "Member Only",
    "contractual_member" => "Contractual Member",
    "registration_agency" => "DOI Registration Agency",
  }.freeze

  REGIONS = {
    "APAC" => "Asia Pacific", "EMEA" => "EMEA", "AMER" => "Americas"
  }.freeze

  def contacts
    authorize! :export, :contacts

    headers = %w[uid fabricaAccountId fabricaId email firstName lastName type createdAt modifiedAt deletedAt isActive]

    rows = Contact.all.reduce([]) do |sum, contact|
      row = {
        "uid" => contact.uid,
        "fabricaAccountId" => contact.provider.symbol,
        "fabricaId" => contact.provider.symbol + "-" + contact.email,
        "email" => contact.email,
        "firstName" => contact.given_name,
        "lastName" => contact.family_name.present? ? contact.family_name : contact.email,
        "type" => contact.role_name ? Array.wrap(contact.role_name).map { |r| r.camelize(:lower) }.join(";") : nil,
        "createdAt" => export_date_string(contact.created_at),
        "modifiedAt" => export_date_string(contact.updated_at),
        "deletedAt" => contact.deleted_at.present? ? export_date_string(contact.deleted_at) : nil,
        "isActive" => contact.deleted_at.blank?,
      }.values

      sum << CSV.generate_line(row)
      sum
    end

    csv = [CSV.generate_line(headers)] + rows
    filename = "contacts-#{Date.today}.csv"
    send_data csv, filename: filename
  end

  def organizations
    authorize! :export, :organizations

    begin
      # Loop through all providers
      page = { size: 1_000, number: 1 }
      response =
        Provider.query(
          nil,
          page: page,
          from_date: params[:from_date],
          until_date: params[:until_date],
          include_deleted: true,
        )
      providers = response.results.to_a

      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

      # keep going for all pages
      page_num = 2
      while page_num <= total_pages
        page = { size: 1_000, number: page_num }
        response =
          Provider.query(
            nil,
            page: page,
            from_date: params[:from_date],
            until_date: params[:until_date],
            include_deleted: true,
          )
        providers = providers + response.results.to_a
        page_num += 1
      end

      headers = [
        "Name",
        "fabricaAccountId",
        "Parent Organization",
        "Is Active",
        "Organization Description",
        "Website",
        "Region",
        "Focus Area",
        "Sector",
        "Member Type",
        "Email",
        "Group Email",
        "billingStreet",
        "Billing Zip/Postal Code",
        "billingCity",
        "Department",
        "billingOrganization",
        "billingStateCode",
        "billingCountryCode",
        "twitter",
        "ROR",
        "Fabrica Creation Date",
        "Fabrica Modification Date",
        "Fabrica Deletion Date",
      ]

      csv = headers.to_csv

      providers.each do |provider|
        row = {
          accountName: provider.name,
          fabricaAccountId: provider.symbol,
          parentFabricaAccountId:
            if provider.consortium_id.present?
              provider.consortium_id.upcase
            end,
          isActive: provider.deleted_at.blank?,
          accountDescription: provider.description,
          accountWebsite: provider.website,
          region:
            provider.region.present? ? export_region(provider.region) : nil,
          focusArea: provider.focus_area,
          sector: provider.organization_type,
          accountType: export_member_type(provider.member_type),
          generalContactEmail: provider.system_email,
          groupEmail: provider.group_email,
          billingStreet: provider.billing_information.address,
          billingPostalCode: provider.billing_information.post_code,
          billingCity: provider.billing_information.city,
          billingDepartment: provider.billing_information.department,
          billingOrganization: provider.billing_information.organization,
          billingStateCode:
            if provider.billing_information.state.present?
              provider.billing_information.state.split("-").last
            end,
          billingCountryCode: provider.billing_information.country,
          twitter: provider.twitter_handle,
          rorId: provider.ror_id,
          created: export_date(provider.created),
          modified: export_date(provider.updated),
          deleted:
            if provider.deleted_at.present?
              export_date(provider.deleted_at)
            end,
        }.values

        csv += CSV.generate_line row
      end

      filename =
        if params[:until_date]
          "organizations-#{params[:until_date]}.csv"
        else
          "organizations-#{Date.today}.csv"
        end

      send_data csv, filename: filename
    rescue StandardError,
           Elasticsearch::Transport::Transport::Errors::BadRequest => e
      render json: { "errors" => { "title" => e.message } }.to_json,
             status: :bad_request
    end
  end

  def repositories
    # authorize! :export, :repositories

    # Loop through all clients
    page = { size: 1_000, number: 1 }
    response =
      Client.query(
        nil,
        page: page,
        from_date: params[:from_date],
        until_date: params[:until_date],
        include_deleted: true,
      )
    clients = response.results.to_a

    total = response.results.total
    total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

    # keep going for all pages
    page_num = 2
    while page_num <= total_pages
      page = { size: 1_000, number: page_num }
      response =
        Client.query(
          nil,
          page: page,
          from_date: params[:from_date],
          until_date: params[:until_date],
          include_deleted: true,
        )
      clients = clients + response.results.to_a
      page_num += 1
    end

    logger.warn "Exporting #{clients.length} repositories."

    # Get doi counts via DOIs query and combine next to clients.
    response =
      DataciteDoi.query(
        nil,
        state: "registered,findable",
        page: { size: 0, number: 1 },
        totals_agg: "client_export",
      )

    client_totals = {}
    totals_buckets = response.aggregations.clients_totals.buckets
    totals_buckets.each do |totals|
      client_totals[totals["key"]] = {
        "count" => totals["doc_count"],
        "this_year" => totals.this_year.buckets[0]["doc_count"],
        "last_year" => totals.last_year.buckets[0]["doc_count"],
      }
    end

    draft_response =
      DataciteDoi.query(
        nil,
        state: "draft",
        page: { size: 0, number: 1 },
        totals_agg: "client_export",
      )

    draft_client_totals = {}
    draft_totals_buckets = draft_response.aggregations.clients_totals.buckets
    draft_totals_buckets.each do |totals|
      draft_client_totals[totals["key"]] = {
        "count" => totals["doc_count"],
        "this_year" => totals.this_year.buckets[0]["doc_count"],
        "last_year" => totals.last_year.buckets[0]["doc_count"],
      }
    end

    headers = [
      "Repository Name",
      "Repository ID",
      "Organization",
      "isActive",
      "Description",
      "Repository URL",
      "generalContactEmail",
      "serviceContactEmail",
      "serviceContactGivenName",
      "serviceContactFamilyName",
      "Fabrica Creation Date",
      "Fabrica Modification Date",
      "Fabrica Deletion Date",
      "doisCurrentYear",
      "doisPreviousYear",
      "doisTotal",
      "doisDraftTotal",
      "doisDbTotal",
      "doisMissing"
    ]

    csv = headers.to_csv

    # get doi counts from database
    dois_by_client = DataciteDoi.group(:datacentre).count

    clients.each do |client|
      # Limit for salesforce default of max 80 chars
      name =
        +client.name.truncate(80)
      # Clean the name to remove quotes, which can break csv parsers
      name.gsub!(/["']/, "")

      db_total = dois_by_client[client.id.to_i].to_i
      es_total = client_totals[client.uid] ? client_totals[client.uid]["count"] : 0
      es_draft_total = draft_client_totals[client.uid] ? draft_client_totals[client.uid]["count"] : 0

      row = {
        accountName: name,
        fabricaAccountId: client.symbol,
        parentFabricaAccountId:
          client.provider.present? ? client.provider.symbol : nil,
        isActive: client.deleted_at.blank?,
        accountDescription: client.description,
        accountWebsite: client.url,
        generalContactEmail: client.system_email,
        serviceContactEmail:
          client.service_contact.present? ? client.service_contact.email : nil,
        serviceContactGivenName:
          if client.service_contact.present?
            client.service_contact.given_name
          end,
        serviceContactFamilyName:
          if client.service_contact.present?
            client.service_contact.family_name
          end,
        created: export_date(client.created),
        modified: export_date(client.updated),
        deleted:
          client.deleted_at.present? ? export_date(client.deleted_at) : nil,
        doisCountCurrentYear:
          if client_totals[client.uid]
            client_totals[client.uid]["this_year"]
          else
            0
          end,
        doisCountPreviousYear:
          if client_totals[client.uid]
            client_totals[client.uid]["last_year"]
          else
            0
          end,
        doisCountTotal: es_total,
        doisCountDraftTotal: es_draft_total,
        doisDbTotal: db_total,
        doisMissing: db_total - (es_total + es_draft_total),
      }.values

      csv += CSV.generate_line row
    end

    filename =
      if params[:until_date]
        "repositories-#{params[:until_date]}.csv"
      else
        "repositories-#{Date.today}.csv"
      end

    send_data csv, filename: filename
  rescue StandardError,
         Elasticsearch::Transport::Transport::Errors::BadRequest => e
    render json: { "errors" => { "title" => e.message } }.to_json,
           status: :bad_request
  end

  def import_dois_not_indexed
    ImportDoisNotIndexedJob.perform_later(nil)
    render plain: "OK",
           status: 202,
           content_type: "text/plain"
  end

  def export_date(date)
    DateTime.strptime(date, "%Y-%m-%dT%H:%M:%S").strftime(
      "%d/%m/%YT%H:%M:%S.%3NUTC%:z",
    )
  end

  def export_date_string(date)
    date.strftime(
      "%d/%m/%YT%H:%M:%S.%3NUTC%:z",
    )
  end

  def export_member_type(member_type)
    MEMBER_TYPES[member_type]
  end

  def export_region(region)
    REGIONS[region]
  end
end
