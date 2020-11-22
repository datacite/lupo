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

      headers = %w[fabricaAccountId fabricaId email firstName lastName type]

      csv = headers.to_csv

      # Use a hashmap for the contacts to avoid duplicated
      contacts = {}

      add_contact =
        Proc.new do |contacts, email, id, firstname, lastname, type|
          if email
            fabrica_id = id + "-" + email
            unless contacts.has_key?(fabrica_id)
              contacts[fabrica_id] = {
                "fabricaAccountId" => id,
                "fabricaId" => fabrica_id,
                "email" => email,
                "firstName" => firstname,
                "lastName" => lastname.presence || email,
              }
            end

            if contacts[fabrica_id].has_key?("type")
              contacts[fabrica_id]["type"] += ";" + type
            else
              contacts[fabrica_id]["type"] = type
            end
          end
        end

      providers.each do |provider|
        if params[:type].blank? || params[:type] == "technical"
          if provider.technical_contact.present?
            add_contact.call(
              contacts,
              provider.technical_contact.email,
              provider.symbol,
              provider.technical_contact.given_name,
              provider.technical_contact.family_name,
              "technical",
            )
          end
          if provider.secondary_technical_contact.present?
            add_contact.call(
              contacts,
              provider.secondary_technical_contact.email,
              provider.symbol,
              provider.secondary_technical_contact.given_name,
              provider.secondary_technical_contact.family_name,
              "secondaryTechnical",
            )
          end
        end

        if params[:type].blank? || params[:type] == "service"
          if provider.service_contact.present?
            add_contact.call(
              contacts,
              provider.service_contact.email,
              provider.symbol,
              provider.service_contact.given_name,
              provider.service_contact.family_name,
              "service",
            )
          end
          if provider.secondary_service_contact.present?
            add_contact.call(
              contacts,
              provider.secondary_service_contact.email,
              provider.symbol,
              provider.secondary_service_contact.given_name,
              provider.secondary_service_contact.family_name,
              "secondaryService",
            )
          end
        end

        if params[:type].blank? || params[:type] == "voting"
          if provider.voting_contact.present?
            add_contact.call(
              contacts,
              provider.voting_contact.email,
              provider.symbol,
              provider.voting_contact.given_name,
              provider.voting_contact.family_name,
              "voting",
            )
          end
        end

        if params[:type].blank? || params[:type] == "billing"
          if provider.billing_contact.present?
            add_contact.call(
              contacts,
              provider.billing_contact.email,
              provider.symbol,
              provider.billing_contact.given_name,
              provider.billing_contact.family_name,
              "billing",
            )
          end
          if provider.secondary_billing_contact.present?
            add_contact.call(
              contacts,
              provider.secondary_billing_contact.email,
              provider.symbol,
              provider.secondary_billing_contact.given_name,
              provider.secondary_billing_contact.family_name,
              "secondaryBilling",
            )
          end
        end
      end

      contacts.each do |_, contact|
        csv +=
          CSV.generate_line [
            contact["fabricaAccountId"],
            contact["fabricaId"],
            contact["email"],
            contact["firstName"],
            contact["lastName"],
            contact["type"],
          ]
      end

      filename =
        if params[:until_date]
          "contacts-#{params.fetch(:type, 'all')}-#{params[:until_date]}.csv"
        else
          "contacts-#{params.fetch(:type, 'all')}-#{Date.today}.csv"
        end

      send_data csv, filename: filename
    rescue StandardError,
           Elasticsearch::Transport::Transport::Errors::BadRequest => e
      Raven.capture_exception(e)

      render json: { "errors" => { "title" => e.message } }.to_json,
             status: :bad_request
    end
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
      Raven.capture_exception(e)

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
    ]

    csv = headers.to_csv

    clients.each do |client|
      # Limit for salesforce default of max 80 chars
      name =
        +client.name.truncate(80)
      # Clean the name to remove quotes, which can break csv parsers
      name.gsub!(/["']/, "")

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
        doisCountTotal:
          client_totals[client.uid] ? client_totals[client.uid]["count"] : 0,
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
    Raven.capture_exception(e)

    render json: { "errors" => { "title" => e.message } }.to_json,
           status: :bad_request
  end

  def export_date(date)
    DateTime.strptime(date, "%Y-%m-%dT%H:%M:%S").strftime(
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
