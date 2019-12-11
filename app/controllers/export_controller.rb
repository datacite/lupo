class ExportController < ApplicationController
    include ActionController::MimeResponds

    before_action :authenticate_user_with_basic_auth!

    def contacts
        authorize! :export, :contacts

        begin
            # Loop through all providers
            providers = []

            page = { size: 1000, number: 1}
            response = Provider.query(nil, page: page, include_deleted: true)
            providers = providers + response.records.to_a

            total = response.results.total
            total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

            # keep going for all pages
            page_num = 2
            while page_num <= total_pages
                page = { size: 1000, number: page_num }
                response = Provider.query(nil, page: page)
                providers = providers + response.records.to_a
                page_num += 1
            end

            respond_to do |format|
                format.csv do
                    headers = %W(
                        fabricaAccountId
                        email
                        firstName
                        lastName
                        type
                    )

                    csv = headers.to_csv

                    providers.each do |provider|

                        csv += CSV.generate_line [
                            provider.symbol,
                            provider.technical_contact_email,
                            provider.technical_contact_given_name,
                            provider.technical_contact_family_name,
                            'technical'
                        ]
                        csv += CSV.generate_line [
                            provider.symbol,
                            provider.secondary_technical_contact_email,
                            provider.secondary_technical_contact_given_name,
                            provider.secondary_technical_contact_family_name,
                            'secondaryTechnicalContact'
                        ]
                        csv += CSV.generate_line [
                            provider.symbol,
                            provider.service_contact_email,
                            provider.service_contact_given_name,
                            provider.service_contact_family_name,
                            'service'
                        ]
                        csv += CSV.generate_line [
                            provider.symbol,
                            provider.secondary_service_contact_email,
                            provider.secondary_service_contact_given_name,
                            provider.secondary_service_contact_family_name,
                            'secondaryService'
                        ]
                        csv += CSV.generate_line [
                            provider.symbol,
                            provider.voting_contact_email,
                            provider.voting_contact_given_name,
                            provider.voting_contact_family_name,
                            'voting'
                        ]
                        csv += CSV.generate_line [
                            provider.symbol,
                            provider.billing_contact_email,
                            provider.billing_contact_given_name,
                            provider.billing_contact_family_name,
                            'billing'
                        ]
                        csv += CSV.generate_line [
                            provider.symbol,
                            provider.secondary_billing_contact_email,
                            provider.secondary_billing_contact_given_name,
                            provider.secondary_billing_contact_family_name,
                            'secondaryBilling'
                        ]

                    end

                    send_data csv, filename: "contacts-#{Date.today}.csv"
                end
            end

        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
            Raven.capture_exception(exception)

            message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

            render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
        end
      end

    def organizations
        authorize! :export, :organizations
        begin
            # Loop through all providers
            providers = []

            page = { size: 1000, number: 1}
            response = Provider.query(nil, page: page, include_deleted: true)
            providers = providers + response.records.to_a

            total = response.results.total
            total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

            # keep going for all pages
            page_num = 2
            while page_num <= total_pages
                page = { size: 1000, number: page_num }
                response = Provider.query(nil, page: page)
                providers = providers + response.records.to_a
                page_num += 1
            end

            respond_to do |format|
                format.csv do
                    headers = %W(
                        accountName
                        fabricaAccountId
                        parentFabricaAccountId
                        salesForceId
                        parentSalesForceId
                        isActive
                        accountDescription
                        accountWebsite
                        region
                        focusArea
                        organisationType
                        accountType
                        generalContactEmail
                        groupEmail
                        billingStreet
                        billingPostalCode
                        billingCity
                        billingDepartment
                        billingOrganization
                        billingState
                        billingCountry
                        twitter
                        rorId
                        created
                        deleted
                        doisCountCurrentYear
                        doisCountPreviousYear
                        doisCountTotal
                    )

                    csv = headers.to_csv

                    providers.each do |provider|
                        row = {
                            accountName: provider.name,
                            fabricaAccountId: provider.symbol,
                            parentFabricaAccountId: provider.consortium.present? ? provider.consortium.symbol : nil,
                            salesForceId: provider.salesforce_id,
                            parentSalesForceId: provider.consortium.present? ? provider.consortium.salesforce_id : nil,
                            isActive: provider.is_active == "\x01",
                            accountDescription: provider.description,
                            accountWebsite: provider.website,
                            region: provider.region_human_name,
                            focusArea: provider.focus_area,
                            organizationType: provider.organization_type,
                            accountType: provider.member_type_label,
                            generalContactEmail: provider.system_email,
                            groupEmail: provider.group_email,
                            billingStreet: provider.billing_address,
                            billingPostalCode: provider.billing_post_code,
                            billingCity: provider.billing_city,
                            billingDepartment: provider.billing_department,
                            billingOrganization: provider.billing_organization,
                            billingState: provider.billing_state,
                            billingCountry: provider.billing_country,
                            twitter: provider.twitter_handle,
                            rorId: provider.ror_id,
                            created: provider.created,
                            deleted: provider.deleted_at,
                            doisCountCurrentYear: nil,
                            doisCountPreviousYear: nil,
                            doisCountTotal: nil
                        }.values

                        csv += CSV.generate_line row
                    end

                    send_data csv, filename: "organizations-#{Date.today}.csv"
                end
            end

        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
            Raven.capture_exception(exception)

            message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

            render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
        end
      end


    def repositories
        authorize! :export, :repositories
        begin
            # Loop through all clients
            clients = []

            page = { size: 1000, number: 1}
            response = Client.query(nil, page: page, include_deleted: true)
            clients = clients + response.records.to_a

            total = response.results.total
            total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

            # keep going for all pages
            page_num = 2
            while page_num <= total_pages
                page = { size: 1000, number: page_num }
                response = Client.query(nil, page: page, include_deleted: true)
                clients = clients + response.records.to_a
                page_num += 1
            end

            # Get doi counts via DOIS query and combine next to clients.
            response = Doi.query(nil, state: "registered,findable", page: { size: 0, number: 1}, totals_agg: "client")

            client_totals = {}
            totals_buckets = response.response.aggregations.clients_totals.buckets
            totals_buckets.each do |totals|
                client_totals[totals["key"]] = {
                    "count" => totals["doc_count"],
                    "this_year" => totals.this_year.buckets[0]["doc_count"],
                    "last_year" => totals.last_year.buckets[0]["doc_count"]
                }
            end

            respond_to do |format|
                format.csv do
                    headers = %W(
                        accountName
                        fabricaAccountId
                        parentFabricaAccountId
                        salesForceId
                        parentSalesForceId
                        isActive
                        accountDescription
                        accountWebsite
                        generalContactEmail
                        created
                        deleted
                        doisCountCurrentYear
                        doisCountPreviousYear
                        doisCountTotal
                    )

                    csv = headers.to_csv

                    clients.each do |client|
                        client_id = client.symbol.downcase
                        row = {
                            accountName: client.name,
                            fabricaAccountId: client.symbol,
                            parentFabricaAccountId: client.provider.present? ? client.provider.symbol : nil,
                            salesForceId: client.salesforce_id,
                            parentSalesForceId: client.provider.present? ? client.provider.salesforce_id : nil,
                            isActive: client.is_active == "\x01",
                            accountDescription: client.description,
                            accountWebsite: client.url,
                            generalContactEmail: client.system_email,
                            created: client.created,
                            deleted: client.deleted_at,
                            doisCountCurrentYear: client_totals[client_id] ? client_totals[client_id]["this_year"] : nil,
                            doisCountPreviousYear: client_totals[client_id] ? client_totals[client_id]["last_year"] : nil,
                            doisCountTotal: client_totals[client_id] ? client_totals[client_id]["count"] : nil
                        }.values

                        csv += CSV.generate_line row
                    end

                    send_data csv, filename: "repositories-#{Date.today}.csv"
                end
            end

        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
            Raven.capture_exception(exception)

            message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

            render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
        end
      end

end