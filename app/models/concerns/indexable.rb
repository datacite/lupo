# frozen_string_literal: true

module Indexable
  extend ActiveSupport::Concern

  require "aws-sdk-sqs"

  included do
    after_commit on: %i[create update] do
      enqueue_index_update

      if instance_of?(DataciteDoi) || instance_of?(OtherDoi) || instance_of?(Doi)
        if aasm_state == "findable"
          changed_attributes = saved_changes
          relevant_changes = changed_attributes.keys & %w[related_identifiers creators funding_references aasm_state]
          if (relevant_changes.any? || (created == updated)) && !ENV["EXCLUDE_PREFIXES_FROM_DATA_IMPORT"].to_s.split(",").include?(prefix)
            send_import_message(to_jsonapi)
            Rails.logger.info "[Event Data Import Message] State: #{aasm_state} Params: #{to_jsonapi} message sent to Event Data service."
          end
        end
      # ignore if record was created via Salesforce API
      elsif instance_of?(Client) && !from_salesforce && (Rails.env.production? || ENV["SQS_PREFIX"] == "stage")
        send_client_export_message(to_jsonapi.merge(slack_output: true))
      end
    end

    after_commit on: [:destroy] do
      deleted_from_active = false
      deleted_from_inactive = false

      # Delete from active index
      begin
        __elasticsearch__.delete_document
        deleted_from_active = true
      rescue Elastic::Transport::Transport::Errors::NotFound => e
        Rails.logger.warn "Document not found in active index: #{e.message}"
      end

      # Delete from inactive index if sync is enabled
      if (instance_of?(DataciteDoi) || instance_of?(OtherDoi)) && index_sync_enabled?
        begin
          __elasticsearch__.delete_document(index: self.class.inactive_index)
          deleted_from_inactive = true
        rescue Elastic::Transport::Transport::Errors::NotFound => e
          Rails.logger.warn "Document not found in inactive index: #{e.message}"
        end
      elsif instance_of?(Client) && !from_salesforce && (Rails.env.production? || ENV["SQS_PREFIX"] == "stage")
        send_client_export_message(to_jsonapi.merge(slack_output: true))
      elsif instance_of?(Provider) && !from_salesforce && (Rails.env.production? || ENV["SQS_PREFIX"] == "stage")
        send_provider_export_message(to_jsonapi.merge(slack_output: true))
      end
      # Only log success if at least one deletion succeeded
      if deleted_from_active || deleted_from_inactive
        if self.class.name == "Event"
          Rails.logger.info "#{self.class.name} #{uuid} deleted from Elasticsearch index."
        else
          Rails.logger.info "#{self.class.name} #{uid} deleted from Elasticsearch index."
        end
      end

      # send_delete_message(self.to_jsonapi) if self.class.name == "Doi" && !Rails.env.test?

      # reindex prefix
      if ["ProviderPrefix", "ClientPrefix"].include?(self.class.name)
        IndexJob.perform_later(self.prefix)
      end
    end

    def enqueue_index_update
      # use index_document instead of update_document to also update virtual attributes
      if ["Doi", "DataciteDoi", "OtherDoi"].include?(self.class.name) && agency != "datacite"
        other_doi = OtherDoi.find_by(id: self.id)
        if other_doi
          OtherDoiImportInBulkJob.perform_later([other_doi.id], { index: self.class.active_index })

          if index_sync_enabled?
            OtherDoiImportInBulkJob.perform_later([other_doi.id], { index: self.class.inactive_index })
          end
        end
      elsif ["Event", "Activity"].include?(self.class.name)
        IndexBackgroundJob.perform_later(self)
      elsif not %w[Prefix ProviderPrefix ClientPrefix DataciteDoi].include?(self.class.name)
        IndexJob.perform_later(self)
      elsif instance_of?(DataciteDoi)
        IndexJobDoiRegistration.perform_later(self)

        if index_sync_enabled?
          DataciteDoiImportInBulkJob.perform_later([id], { index: self.class.inactive_index })
        end
      else
        __elasticsearch__.index_document
        # This is due to the order of indexing, we want to always ensure
        # the prefix index is up to date with relations
        # So we force it here to reindex prefix if we touch them.
        if ["ProviderPrefix", "ClientPrefix"].include?(self.class.name)
          self.prefix.__elasticsearch__.index_document
        end
      end
    end

    def send_delete_message(data)
      send_message(data, shoryuken_class: "DoiDeleteWorker", queue_name: "doi")
    end

    def send_import_message(data)
      send_message(data, shoryuken_class: "DoiImportWorker", queue_name: "doi")
    end

    def send_provider_export_message(data)
      send_message(data, shoryuken_class: "ProviderExportWorker", queue_name: "salesforce")
    end

    def send_client_export_message(data)
      send_message(data, shoryuken_class: "ClientExportWorker", queue_name: "salesforce")
    end

    def send_contact_export_message(data)
      send_message(data, shoryuken_class: "ContactExportWorker", queue_name: "salesforce")
    end

    # shoryuken_class is needed for the consumer to process the message
    # SQS interaction is handled by SqsMessageService
    def send_message(body, options = {})
      SqsMessageService.enqueue(body, options)
    end

    def ror_from_url(url)
      ror = Array(%r{\A(?:(http|https)://)?(ror\.org/)?(.+)}.match(url)).last
      "ror.org/#{ror}" if ror.present?
    end
  end

  module ClassMethods
    # return results for one or more ids
    def find_by_id(ids, options = {})
      ids = ids.split(",") if ids.is_a?(String)
      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 2_000

      options[:sort] ||= if %w[Prefix ProviderPrefix ClientPrefix].include?(name)
        { created_at: { order: "asc" } }
      else
        { created: { order: "asc" } }
      end

      __elasticsearch__.search(
        from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
        size: options.dig(:page, :size),
        sort: [options[:sort]],
        track_total_hits: true,
        query: { terms: { symbol: ids.map(&:upcase) } },
        aggregations: query_aggregations,
      )
    end

    def find_by_id_list(ids, options = {})
      options[:sort] ||= { "_doc" => { order: "asc" } }

      __elasticsearch__.search(
        from:
          if options[:page].present?
            (options.dig(:page, :number) - 1) * options.dig(:page, :size)
          else
            0
          end,
        size: options[:size] || 25,
        sort: [options[:sort]],
        track_total_hits: true,
        query: { terms: { id: ids.split(",") } },
        aggregations: query_aggregations,
      )
    end

    def query(query, options = {})
      # support scroll api
      # map function is small performance hit
      if options[:scroll_id].present? && options.dig(:page, :scroll)
        begin
          response =
            __elasticsearch__.client.scroll(
              body: {
                scroll_id: options[:scroll_id],
                scroll: options.dig(:page, :scroll),
              },
            )
          return Hashie::Mash.new(
            total: response.dig("hits", "total", "value"),
            results: response.dig("hits", "hits").map { |r| r["_source"] },
            scroll_id: response["_scroll_id"],
          )
          # handle expired scroll_id (Elasticsearch returns this error)
        rescue Elastic::Transport::Transport::Errors::NotFound
          return Hashie::Mash.new(total: 0, results: [], scroll_id: nil)
        end
      end

      aggregations =
        if options[:totals_agg] == "provider"
          provider_aggregations
        elsif options[:totals_agg] == "client"
          client_aggregations
        elsif options[:totals_agg] == "client_export"
          client_export_aggregations
        elsif options[:totals_agg] == "prefix"
          prefix_aggregations
        else
          query_aggregations
        end

      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 25

      # Cursor nav use the search after, this should always be an array of values that match the sort.
      if options.fetch(:page, {}).key?(:cursor)
        # make sure we have a valid cursor
        cursor = [0, ""]
        if options.dig(:page, :cursor).is_a?(Array)
          timestamp, uid = options.dig(:page, :cursor)
          cursor = [timestamp.to_i, uid.to_s]
        elsif options.dig(:page, :cursor).is_a?(String)
          timestamp, uid = options.dig(:page, :cursor).split(",")
          cursor = [timestamp.to_i, uid.to_s]
        end

        search_after = cursor
        from = 0
        sort =
          if name == "Event"
            [{ created_at: "asc", uuid: "asc" }]
          elsif name == "Activity"
            [{ created: "asc", request_uuid: "asc" }]
          elsif %w[Client Provider].include?(name)
            [{ created: "asc", uid: "asc" }]
          elsif %w[Prefix ProviderPrefix ClientPrefix].include?(name)
            [{ created_at: "asc", uid: "asc" }]
          else
            [{ created: "asc" }]
          end
      else
        from =
          ((options.dig(:page, :number) || 1) - 1) *
          (options.dig(:page, :size) || 25)
        search_after = nil
        sort = options[:sort]
      end

      # make sure field name uses underscore
      # escape forward slashes in query
      if query.present?
        query = query.gsub(/publicationYear/, "publication_year")
        query = query.gsub(/relatedIdentifiers/, "related_identifiers")
        query = query.gsub(/rightsList/, "rights_list")
        query = query.gsub(/fundingReferences/, "funding_references")
        query = query.gsub(/geoLocations/, "geo_locations")
        query = query.gsub(/landingPage/, "landing_page")
        query = query.gsub(/contentUrl/, "content_url")
        query = query.gsub("/", "\/")
      end

      must_not = []
      filter = []
      should = []
      minimum_should_match = 0

      # filters for some classes

      if name == "Provider"
        must = if query.present?
          [
            {
              query_string: {
                query: query,
                fields: query_fields,
                default_operator: "AND",
                phrase_slop: 1,
              },
            },
          ]
        else
          [{ match_all: {} }]
        end

        if options[:year].present?
          filter <<
            {
              range: {
                created: {
                  gte: "#{options[:year].split(',').min}||/y",
                  lte: "#{options[:year].split(',').max}||/y",
                  format: "yyyy",
                },
              },
            }
        end
        if options[:from_date].present?
          filter <<
            { range: { updated: { gte: "#{options[:from_date]}||/d" } } }
        end
        if options[:until_date].present?
          filter <<
            { range: { updated: { lte: "#{options[:until_date]}||/d" } } }
        end
        if options[:region].present?
          filter << { term: { 'region': options[:region].upcase } }
        end
        if options[:iso3166_world_region].present?
          filter << { term: { 'country.iso3166_world_region': options[:iso3166_world_region].upcase } }
        end
        if options[:iso3166_region].present?
          filter << { term: { 'country.iso3166_region': options[:iso3166_region] } }
        end
        if options[:iso3166_subregion].present?
          filter << { term: { 'country.iso3166_subregion': options[:iso3166_subregion] } }
        end
        if options[:consortium_id].present?
          filter << { term: { "consortium_id": { value: options[:consortium_id], case_insensitive: true  } } }
        end
        if options[:member_type].present?
          filter << { terms: { member_type: options[:member_type].split(",") } }
        end
        if options[:organization_type].present?
          filter <<
            {
              terms: {
                organization_type: options[:organization_type].split(","),
              },
            }
        end
        if options[:non_profit_status].present?
          filter << { term: { non_profit_status: options[:non_profit_status] == 1 } }
        end
        if options[:has_required_contacts].present?
          filter << { term: { has_required_contacts: options[:has_required_contacts] } }
        end
        if options[:focus_area].present?
          filter << { terms: { focus_area: options[:focus_area].split(",") } }
        end

        unless options[:include_deleted].present?
          must_not << { exists: { field: "deleted_at" } }
        end
        must_not << { term: { role_name: "ROLE_ADMIN" } }
      elsif name == "Client"
        must = if query.present?
          [
            {
              query_string: {
                query: query,
                fields: query_fields,
                default_operator: "AND",
                phrase_slop: 1,
              },
            },
          ]
        else
          [{ match_all: {} }]
        end

        if options[:year].present?
          filter <<
            {
              range: {
                created: {
                  gte: "#{options[:year].split(',').min}||/y",
                  lte: "#{options[:year].split(',').max}||/y",
                  format: "yyyy",
                },
              },
            }
        end
        if options[:from_date].present?
          filter <<
            { range: { updated: { gte: "#{options[:from_date]}||/d" } } }
        end
        if options[:until_date].present?
          filter <<
            { range: { updated: { lte: "#{options[:until_date]}||/d" } } }
        end
        if options[:provider_id].present?
          options[:provider_id].split(",").each { |id|
            should << { term: { "provider_id": { value: id, case_insensitive: true } } }
          }
          minimum_should_match = 1
        end
        if options[:software].present?
          filter <<
            { terms: { "software.raw" => options[:software].split(",") } }
        end
        if options[:certificate].present?
          filter << { terms: { certificate: options[:certificate].split(",") } }
        end
        if options[:repository_type].present?
          filter <<
            { terms: { repository_type: options[:repository_type].split(",") } }
        end
        if options[:consortium_id].present?
          filter << { term: { consortium_id: { value: options[:consortium_id], case_insensitive: true } } }
        end
        if options[:re3data_id].present?
          filter <<
            {
              term: { re3data_id: options[:re3data_id].gsub("/", "\/").upcase },
            }
        end
        if options[:opendoar_id].present?
          filter << { term: { opendoar_id: options[:opendoar_id] } }
        end
        if options[:client_type].present?
          filter << { term: { client_type: options[:client_type] } }
        end
        unless options[:include_deleted].present?
          must_not << { exists: { field: "deleted_at" } }
        end
      elsif name == "Event"
        must = if query.present?
          [
            {
              query_string: {
                query: query,
                fields: query_fields,
                default_operator: "AND",
                phrase_slop: 1,
              },
            },
          ]
        else
          [{ match_all: {} }]
        end

        if options[:subj_id].present?
          filter << { term: { subj_id: CGI.unescape(options[:subj_id]) } }
        end
        if options[:obj_id].present?
          filter << { term: { obj_id: CGI.unescape(options[:obj_id]) } }
        end
        if options[:citation_type].present?
          filter << { term: { citation_type: options[:citation_type] } }
        end
        if options[:year_month].present?
          filter << { term: { year_month: options[:year_month] } }
        end
        if options[:publication_year].present?
          filter <<
            {
              range: {
                "subj.datePublished" => {
                  gte: "#{options[:publication_year].split('-').min}||/y",
                  lte: "#{options[:publication_year].split('-').max}||/y",
                  format: "yyyy",
                },
              },
            }
        end
        if options[:occurred_at].present?
          filter <<
            {
              range: {
                occurred_at: {
                  gte: "#{options[:occurred_at].split('-').min}||/y",
                  lte: "#{options[:occurred_at].split('-').max}||/y",
                  format: "yyyy",
                },
              },
            }
        end
        if options[:prefix].present?
          filter << { terms: { prefix: options[:prefix].split(",") } }
        end
        if options[:doi].present?
          filter << { terms: { doi: options[:doi].downcase.split(",") } }
        end
        if options[:source_doi].present?
          filter <<
            { terms: { source_doi: options[:source_doi].downcase.split(",") } }
        end
        if options[:target_doi].present?
          filter <<
            { terms: { target_doi: options[:target_doi].downcase.split(",") } }
        end
        if options[:orcid].present?
          filter << { terms: { orcid: options[:orcid].split(",") } }
        end
        if options[:isni].present?
          filter << { terms: { isni: options[:isni].split(",") } }
        end
        if options[:subtype].present?
          filter << { terms: { subtype: options[:subtype].split(",") } }
        end
        if options[:source_id].present?
          filter << { terms: { source_id: options[:source_id].split(",") } }
        end
        if options[:relation_type_id].present?
          filter <<
            {
              terms: { relation_type_id: options[:relation_type_id].split(",") },
            }
        end
        if options[:source_relation_type_id].present?
          filter <<
            {
              terms: {
                source_relation_type_id:
                  options[:source_relation_type_id].split(","),
              },
            }
        end
        if options[:target_relation_type_id].present?
          filter <<
            {
              terms: {
                target_relation_type_id:
                  options[:target_relation_type_id].split(","),
              },
            }
        end
        if options[:registrant_id].present?
          filter <<
            { terms: { registrant_id: options[:registrant_id].split(",") } }
        end
        if options[:provider_id].present?
          options[:provider_id].split(",").each { |id|
            should << { term: { "provider_ids": { value: id, case_insensitive: true } } }
          }
          minimum_should_match = 1
        end
        if options[:issn].present?
          filter << { terms: { issn: options[:issn].split(",") } }
        end

        if options[:update_target_doi].present?
          must_not << { exists: { field: "target_doi" } }
        end
      elsif name == "Prefix"
        must =
          query.present? ? [{ prefix: { prefix: query } }] : [{ match_all: {} }]

        if options[:year].present?
          filter <<
            {
              range: {
                created_at: {
                  gte: "#{options[:year].split(',').min}||/y",
                  lte: "#{options[:year].split(',').max}||/y",
                  format: "yyyy",
                },
              },
            }
        end
        if options[:provider_id].present?
          options[:provider_id].split(",").each { |id|
            should << { term: { "provider_ids": { value: id, case_insensitive: true } } }
          }
          minimum_should_match = 1
        end
        if options[:client_id].present?
          options[:client_id].split(",").each { |id|
            should << { term: { "client_ids": { value: id, case_insensitive: true } } }
          }
          minimum_should_match = 1
        end
        if options[:state].present?
          filter << { terms: { state: options[:state].to_s.split(",") } }
        end
      elsif name == "ProviderPrefix"
        must =
          if query.present?
            [{ prefix: { prefix_id: query } }]
          else
            [{ match_all: {} }]
          end

        if options[:year].present?
          filter <<
            {
              range: {
                created_at: {
                  gte: "#{options[:year].split(',').min}||/y",
                  lte: "#{options[:year].split(',').max}||/y",
                  format: "yyyy",
                },
              },
            }
        end
        if options[:provider_id].present?
          options[:provider_id].split(",").each { |id|
            should << { term: { "provider_id": { value: id, case_insensitive: true } } }
          }
          minimum_should_match = 1
        end
        if options[:consortium_organization_id].present?
          options[:consortium_organization_id].split(",").each { |id|
            should << { term: { "provider_id": { value: id, case_insensitive: true } } }
          }
          minimum_should_match = 1
        end
        if options[:consortium_id].present?
          filter << { term: { consortium_id: { value: options[:consortium_id], case_insensitive: true  } } }
        end
        if options[:prefix_id].present?
          filter << { term: { prefix_id: options[:prefix_id] } }
        end
        if options[:uid].present?
          filter << { terms: { uid: options[:uid].to_s.split(",") } }
        end
        if options[:state].present?
          filter << { terms: { state: options[:state].to_s.split(",") } }
        end
      elsif name == "ClientPrefix"
        must =
          if query.present?
            [{ prefix: { prefix_id: query } }]
          else
            [{ match_all: {} }]
          end

        if options[:year].present?
          filter <<
            {
              range: {
                created_at: {
                  gte: "#{options[:year].split(',').min}||/y",
                  lte: "#{options[:year].split(',').max}||/y",
                  format: "yyyy",
                },
              },
            }
        end
        if options[:client_id].present?
          options[:client_id].split(",").each { |id|
            should << { term: { "client_id": { value: id, case_insensitive: true } } }
          }
          minimum_should_match = 1
        end
        if options[:prefix_id].present?
          filter << { term: { "prefix_id": { value: options[:prefix_id], case_insensitive: true  } } }
        end
      elsif name == "Activity"
        must = if query.present?
          [
            {
              query_string: {
                query: query,
                fields: query_fields,
                default_operator: "AND",
                phrase_slop: 1,
              },
            },
          ]
        else
          [{ match_all: {} }]
        end

        if options[:uid].present?
          filter << { terms: { uid: options[:uid].to_s.split(",") } }
        end
      elsif name == "Contact"
        must = if query.present?
          [
            {
              query_string: {
                query: query,
                fields: query_fields
              },
            },
          ]
        else
          [{ match_all: {} }]
        end

        if options[:provider_id].present?
          filter << { term: { "provider_id": { value: options[:provider_id], case_insensitive: true } } }
        end

        # match either consortium_id or provider_id
        if options[:consortium_id].present?
          should << { term: { provider_id: { value: options[:consortium_id], case_insensitive: true } } }
          should << { term: { consortium_id: { value: options[:consortium_id], case_insensitive: true } } }
          minimum_should_match = 1
        end

        if options[:role_name].present?
          filter << { term: { role_name: options[:role_name] } }
        end
        unless options[:include_deleted].present?
          must_not << { exists: { field: "deleted_at" } }
        end
      end

      # ES query can be optionally defined in different ways
      # So here we build it differently based upon options
      # This is mostly useful when trying to wrap it in a function_score query
      es_query = {}

      # The main bool query with filters
      bool_query = {
        must: must,
        must_not: must_not,
        filter: filter,
        should: should,
        minimum_should_match: minimum_should_match
      }

      # Function score is used to provide varying score to return different values
      # We use the bool query above as our principle query
      # Then apply additional function scoring as appropriate
      # Note this can be performance intensive.
      function_score = {
        query: { bool: bool_query },
        random_score: {
          "seed":
            Rails.env.test? ? "random_1234" : "random_#{rand(1...100_000)}",
        },
      }

      if options[:random].present?
        es_query["function_score"] = function_score
        # Don't do any sorting for random results
        sort = nil
      else
        es_query["bool"] = bool_query
      end

      # Sample grouping is optional included aggregation
      if options[:sample_group].present?
        aggregations[:samples] = {
          terms: { field: options[:sample_group], size: 10_000 },
          aggs: {
            "samples_hits": {
              top_hits: { size: options[:sample_size].presence || 1 },
            },
          },
        }
      end

      # three options for going through results are scroll, cursor and pagination
      # the default is pagination
      # scroll is triggered by the page[scroll] query parameter
      # cursor is triggered by the page[cursor] query parameter

      # can't use search wrapper function for scroll api
      # map function for scroll is small performance hit
      if options.dig(:page, :scroll).present?
        response =
          __elasticsearch__.client.search(
            index: index_name,
            scroll: options.dig(:page, :scroll),
            body: {
              size: options.dig(:page, :size),
              sort: sort,
              query: es_query,
              aggregations: aggregations,
              track_total_hits: true,
            }.compact,
          )
        Hashie::Mash.new(
          total: response.dig("hits", "total", "value"),
          results: response.dig("hits", "hits").map { |r| r["_source"] },
          scroll_id: response["_scroll_id"],
        )
      elsif options.fetch(:page, {}).key?(:cursor)
        __elasticsearch__.search(
          {
            size: options.dig(:page, :size),
            search_after: search_after,
            sort: sort,
            query: es_query,
            aggregations: aggregations,
            track_total_hits: true,
          }.compact,
        )
      else
        __elasticsearch__.search(
          {
            size: options.dig(:page, :size),
            from: from,
            sort: sort,
            query: es_query,
            aggregations: aggregations,
            track_total_hits: true,
          }.compact,
        )
      end
    end

    def count
      Elasticsearch::Model.client.count(index: index_name)["count"]
    end

    # Aliasing
    #
    # We are using two indexes, where one is active (used for API calls) via aliasing and the other one
    # is inactive. All index configuration changes and bulk importing from the database
    # happen in the inactive index.
    #
    # For initial setup run "create_index".
    #
    # Run "upgrade_index" whenever there are changes in the mappings or settings.
    # Follow this by "import" to fill the new index, then use "switch_index" to
    # alias the new index and remove the previous alias from current index.
    #
    # TODO: automatically switch aliases when "import" is done. Not easy, as "import"
    # runs as background jobs.

    # track reindexing via the tasks API
    def monitor_reindex
      client = Elasticsearch::Model.client
      tasks = client.tasks.list(actions: "*reindex")
      tasks.fetch("nodes", {}).inspect
    end

    # create alias
    def create_alias(options = {})
      alias_name = options[:alias] || index_name
      target_index = options[:index] || "#{index_name}_v1"

      IndexAliasCoordination.with_lock(alias_name) do
        with_alias_mutation_locked(alias_name) do
          client = Elasticsearch::Model.client

          if client.indices.exists_alias?(name: alias_name, index: [target_index])
            "Alias #{alias_name} for index #{target_index} already exists."
          else
            # alias index is writeable unless it is for OtherDoi index
            response = client.indices.update_aliases(
              body: {
                actions: [
                  {
                    add: {
                      index: target_index,
                      alias: alias_name,
                      is_write_index: name != "OtherDoi",
                    },
                  },
                ],
              },
            )
            ensure_alias_update_acknowledged!(response, alias_name)

            "Created alias #{alias_name} for index #{target_index}."
          end
        end
      end
    end

    # list all aliases
    def list_aliases
      client = Elasticsearch::Model.client
      cat_client = Elasticsearch::API::Cat::CatClient.new(client)
      puts cat_client.aliases(s: "alias")
    end

    # delete alias
    def delete_alias(options = {})
      alias_name = options[:alias] || index_name
      primary_index = "#{options[:index] || index_name}_v1"
      alternate_index = "#{options[:index] || index_name}_v2"

      IndexAliasCoordination.with_lock(alias_name) do
        with_alias_mutation_locked(alias_name) do
          client = Elasticsearch::Model.client
          message = nil

          if client.indices.exists_alias?(name: alias_name, index: [primary_index])
            client.indices.delete_alias index: primary_index, name: alias_name
            message = "Deleted alias #{alias_name} for index #{primary_index}."
          end
          if client.indices.exists_alias?(name: alias_name, index: [alternate_index])
            client.indices.delete_alias index: alternate_index, name: alias_name
            message = "Deleted alias #{alias_name} for index #{alternate_index}."
          end

          message
        end
      end
    end

    # create both indexes used for aliasing
    def create_index(options = {})
      alias_name = options[:alias] || index_name
      primary_index = "#{options[:index] || index_name}_v1"
      alternate_index = "#{options[:index] || index_name}_v2"

      IndexAliasCoordination.with_lock(alias_name) do
        with_alias_mutation_locked(alias_name) do
          client = Elasticsearch::Model.client

          # delete index if it has the same name as the alias
          if __elasticsearch__.index_exists?(index: alias_name) &&
              !client.indices.exists_alias?(name: alias_name)
            __elasticsearch__.delete_index!(index: alias_name)
          end

          create_template if name == "DataciteDoi" || name == "OtherDoi"

          unless __elasticsearch__.index_exists?(index: primary_index)
            __elasticsearch__.create_index!(index: primary_index)
          end
          unless __elasticsearch__.index_exists?(index: alternate_index)
            __elasticsearch__.create_index!(index: alternate_index)
          end

          "Created indexes #{primary_index} and #{alternate_index}."
        end
      end
    end

    # delete index and both indexes used for aliasing
    def delete_index(options = {})
      if options[:index]
        delete_named_index(options[:index], force: options[:force] == true)
      else
        IndexAliasCoordination.with_lock(index_name) do
          with_alias_mutation_locked(index_name) do
            primary_index = "#{index_name}_v1"
            alternate_index = "#{index_name}_v2"

            if __elasticsearch__.index_exists?(index: primary_index)
              __elasticsearch__.delete_index!(index: primary_index)
            end
            if __elasticsearch__.index_exists?(index: alternate_index)
              __elasticsearch__.delete_index!(index: alternate_index)
            end

            "Deleted indexes #{primary_index} and #{alternate_index}."
          end
        end
      end
    end

    # list all indices
    def list_indices
      client = Elasticsearch::Model.client
      cat_client = Elasticsearch::API::Cat::CatClient.new(client)
      puts cat_client.indices(s: "index")
    end

    # delete and create inactive index to use current mappings
    # Needs to run every time we change the mappings.
    # The target comes from live alias state under the alias lock, never from
    # the cache. A missing or ambiguous alias fails closed.
    def upgrade_index(options = {})
      alias_name = index_name
      IndexAliasCoordination.with_lock(alias_name) do
        with_alias_mutation_locked(alias_name) do
          target = destructive_inactive_target_locked!(alias_name, explicit: options[:index])
          __elasticsearch__.create_index!(index: target, force: true)
          messages = ["Upgraded inactive index #{target}."]
          if options.key?(:refresh_interval)
            messages << set_refresh_interval(target, options[:refresh_interval])
          end
          messages.join("\n")
        end
      end
    end

    # show stats for both indexes
    def index_stats(options = {})
      active_index = options[:active_index] || self.active_index
      inactive_index = options[:inactive_index] || self.inactive_index
      client = Elasticsearch::Model.client

      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_active_index = DataciteDoi.active_index
      #   datacite_inactive_index = DataciteDoi.inactive_index
      #   other_active_index = OtherDoi.active_index
      #   other_inactive_index = OtherDoi.inactive_index

      #   stats = client.indices.stats index: [datacite_active_index, datacite_inactive_index], docs: true
      #   active_index_count = stats.dig("indices", datacite_active_index, "primaries", "docs", "count")
      #   inactive_index_count = stats.dig("indices", datacite_inactive_index, "primaries", "docs", "count")
      #   database_count = DataciteDoi.all.count

      #   "Active index #{active_index} has #{active_index_count} documents, " \
      #     "inactive index #{inactive_index} has #{inactive_index_count} documents, " \
      #     "database has #{database_count} documents."

      #   stats = client.indices.stats index: [other_active_index, other_inactive_index], docs: true
      #   active_index_count = stats.dig("indices", other_active_index, "primaries", "docs", "count")
      #   inactive_index_count = stats.dig("indices", other_inactive_index, "primaries", "docs", "count")
      #   database_count = OtherDoi.all.count

      #   "Active index #{active_index} has #{active_index_count} documents, " \
      #     "inactive index #{inactive_index} has #{inactive_index_count} documents, " \
      #     "database has #{database_count} documents."
      # else
      stats =
        client.indices.stats index: [active_index, inactive_index], docs: true
      active_index_count =
        stats.dig("indices", active_index, "primaries", "docs", "count")
      inactive_index_count =
        stats.dig("indices", inactive_index, "primaries", "docs", "count")

      # workaround until STI is enabled
      database_count =
        if name == "DataCiteDoi"
          where(type: "DataCiteDoi").count
        elsif name == "OtherDoi"
          where(type: "OtherDoi").count
        else
          all.count
        end

      "Active index #{active_index} has #{active_index_count} documents, " \
        "inactive index #{inactive_index} has #{
          inactive_index_count
        } documents, " \
        "database has #{database_count} documents."
      # end
    end

    # Active-index cache for an alias.
    #
    # Invariants:
    # 1. Readers never overwrite a value that is already present. This change
    #    still populates a miss with a plain write; the add-only read path
    #    follows in a later change.
    # 2. Mutators overwrite under the per-alias MySQL advisory lock, from a
    #    live OpenSearch lookup, and read the value back.
    # 3. Destructive targets come from live alias state under that lock.
    #    Missing or ambiguous alias state fails closed.
    #
    # Manual OpenSearch changes and processes that do not go through these
    # methods bypass the lock and the invalidation. The 60s TTL only bounds
    # that exposure.
    ACTIVE_INDEX_CACHE_TTL = IndexAliasCoordination::TTL

    def active_index_cache_key(alias_name = index_name)
      IndexAliasCoordination.cache_key(alias_name)
    end

    # Replace the cached active index with a live OpenSearch lookup.
    def refresh_index_name_cache!(alias_name = index_name)
      IndexAliasCoordination.with_lock(alias_name) do
        refresh_index_name_cache_locked(alias_name)
      end
    end

    # switch between the two indexes, i.e. the index that is aliased
    # alias index for OtherDoi by default is not writeable,
    # as we also have DataciteDoi alias
    def switch_index(options = {})
      alias_name = options[:alias] || index_name
      primary_index = "#{options[:index] || index_name}_v1"
      alternate_index = "#{options[:index] || index_name}_v2"
      is_write_index = options[:is_write_index] || name != "OtherDoi"

      IndexAliasCoordination.with_lock(alias_name) do
        with_alias_mutation_locked(alias_name) do
          holders = IndexAliasCoordination.fetch_live(alias_name).holders
          client = Elasticsearch::Model.client

          if holders.include?(primary_index)
            response = client.indices.update_aliases body: {
              actions: [
                { remove: { index: primary_index, alias: alias_name } },
                {
                  add: {
                    index: alternate_index,
                    alias: alias_name,
                    is_write_index: is_write_index,
                  },
                },
              ],
            }
            ensure_alias_update_acknowledged!(response, alias_name)
            "Switched active index to #{alternate_index}."
          elsif holders.include?(alternate_index)
            response = client.indices.update_aliases body: {
              actions: [
                { remove: { index: alternate_index, alias: alias_name } },
                {
                  add: {
                    index: primary_index,
                    alias: alias_name,
                    is_write_index: is_write_index,
                  },
                },
              ],
            }
            ensure_alias_update_acknowledged!(response, alias_name)
            "Switched active index to #{primary_index}."
          end
        end
      end
    end

    # Return the active index, i.e. the index that is aliased.
    # Result is cached; failures are not cached and return nil without raising.
    # A miss still uses a plain write. The add-only read path is a follow-up.
    def active_index(alias_name = index_name)
      key = active_index_cache_key(alias_name)
      cached = Rails.cache.read(key)
      return cached if cached.present?

      fetched = fetch_active_index_from_elasticsearch(alias_name)
      if fetched.present?
        Rails.cache.write(key, fetched, expires_in: ACTIVE_INDEX_CACHE_TTL)
      end
      fetched
    end

    # Query Elasticsearch for the write index behind the alias.
    # Don't rely on the first index being the correct one.
    # Transport errors return nil. NotFound is an empty alias, also nil.
    def fetch_active_index_from_elasticsearch(alias_name = index_name)
      IndexAliasCoordination.fetch_live(alias_name).active
    rescue Elastic::Transport::Transport::Error => e
      Rails.logger.error(
        "[Elasticsearch] Error fetching active index for alias #{alias_name}: #{e.class} #{e.message}",
      )
      nil
    end

    # Return the inactive index, i.e. the index that is not aliased.
    # Still derived from the cache. Used only for non-destructive defaults.
    def inactive_index(alias_name = index_name, base: index_name)
      resolved = active_index(alias_name)
      return nil if resolved.nil?

      primary_index = "#{base}_v1"
      alternate_index = "#{base}_v2"
      resolved.end_with?("v1") ? alternate_index : primary_index
    end

    # Live _v1/_v2 complement of the alias. Does not take the alias lock.
    # Raises when the alias is missing, ambiguous, or not on _v1/_v2.
    def live_inactive_index!(alias_name = index_name, base: index_name)
      state = IndexAliasCoordination.fetch_live(alias_name)
      expected = ["#{base}_v1", "#{base}_v2"]
      active = state.holders.size == 1 ? state.holders.first : nil
      unless active && expected.include?(active)
        raise IndexAliasCoordination::UnsafeIndexOperation,
          "Cannot resolve inactive index for #{alias_name}: holders #{state.holders.inspect}"
      end

      (expected - [active]).first
    end

    # Set the refresh interval for a given index.
    # A nil or empty interval means "120s" rather than resetting the index
    # to the cluster default. A nil index resolves the inactive index live.
    def set_refresh_interval(index, refresh_interval = "120s")
      refresh_interval = refresh_interval.presence || "120s"
      client = Elasticsearch::Model.client
      index_to_update = index.nil? ? live_inactive_index! : index

      unless client.indices.exists index: index_to_update
        return "Index '#{index_to_update}' not found."
      end

      response = client.indices.put_settings(
        index: index_to_update,
        body: {
          index: {
            refresh_interval: refresh_interval,
          },
        },
      )

      if response.to_h["acknowledged"]
        "Successfully updated refresh interval for index '#{index_to_update}' to '#{refresh_interval}'."
      else
        "Failed to update refresh interval for index '#{index_to_update}'."
      end
    end

    # Assumes the alias lock is held. Resyncs from live OpenSearch after the
    # block, including when the block raises. The original exception wins.
    def with_alias_mutation_locked(alias_name)
      result = yield
      refresh_index_name_cache_locked(alias_name)
      result
    rescue StandardError => e
      begin
        refresh_index_name_cache_locked(alias_name)
      rescue StandardError => cleanup
        Rails.logger.error(
          "[IndexAlias] cache resync after failed mutation of #{alias_name} failed: #{cleanup.class} #{cleanup.message}",
        )
        begin
          Rails.cache.delete(active_index_cache_key(alias_name))
        rescue StandardError
          nil
        end
      end
      raise e
    end

    def refresh_index_name_cache_locked(alias_name)
      value = IndexAliasCoordination.fetch_live(alias_name).active
      IndexAliasCoordination.write_authoritative!(alias_name, value)
      value
    end

    def destructive_inactive_target_locked!(alias_name, explicit:)
      expected = ["#{index_name}_v1", "#{index_name}_v2"]
      state = IndexAliasCoordination.fetch_live(alias_name)
      active = state.holders.size == 1 ? state.holders.first : nil
      unless active && expected.include?(active)
        raise IndexAliasCoordination::UnsafeIndexOperation,
          "Refusing to upgrade #{alias_name}: expected exactly one of #{expected.join(', ')} " \
          "to hold the alias, holders were #{state.holders.inspect}"
      end

      computed = (expected - [active]).first
      unless explicit.nil?
        unless expected.include?(explicit) && explicit != active
          raise IndexAliasCoordination::UnsafeIndexOperation,
            "Refusing to upgrade explicit target #{explicit.inspect} for #{alias_name}; active is #{active}"
        end
        return explicit
      end

      computed
    end

    def delete_named_index(target, force:)
      IndexAliasCoordination.with_lock(index_name) do
        aliases = aliases_on_index(target)
        if aliases.any? && !force
          raise IndexAliasCoordination::UnsafeIndexOperation,
            "Refusing to delete index #{target} because it is aliased by #{aliases.join(', ')}. " \
            "Pass force: true to override."
        end

        extras = aliases.reject { |candidate| candidate == index_name }
        with_extra_alias_locks(extras) do
          if aliases.any?
            Rails.logger.warn(
              "[IndexAlias] Deleting index #{target} with force; aliases that will disappear: #{aliases.join(', ')}",
            )
          end

          with_alias_mutation_locked(index_name) do
            __elasticsearch__.delete_index!(index: target)
            extras.each { |extra| refresh_index_name_cache_locked(extra) }
            "Deleted index #{target}."
          end
        end
      end
    end

    def with_extra_alias_locks(alias_names, &block)
      return yield if alias_names.empty?

      head, *tail = alias_names
      IndexAliasCoordination.with_lock(head) do
        with_extra_alias_locks(tail, &block)
      end
    end

    def aliases_on_index(target)
      response = Elasticsearch::Model.client.indices.get_alias(index: target)
      response.each_value.flat_map do |meta|
        raw = meta["aliases"] || meta[:aliases] || {}
        raw.keys.map(&:to_s)
      end
    rescue Elastic::Transport::Transport::Errors::NotFound
      []
    end

    def ensure_alias_update_acknowledged!(response, alias_name)
      return if alias_update_acknowledged?(response)

      holders = IndexAliasCoordination.fetch_live(alias_name).holders
      raise IndexAliasCoordination::AliasUpdateUnacknowledged,
        "OpenSearch did not acknowledge the alias update for #{alias_name}; live holders: #{holders.inspect}"
    end

    def alias_update_acknowledged?(response)
      return false unless response.respond_to?(:[])

      value = response["acknowledged"]
      value = response[:acknowledged] if value.nil?
      value == true
    end

    # create index template
    def create_template
      alias_name = index_name

      body =
        if name == "DataciteDoi" || name == "Doi"
          {
            # Avoid "dois*" — it also matches dois-other*
            index_patterns: [alias_name, "#{alias_name}_v1", "#{alias_name}_v2"],
            settings: name == "DataciteDoi" ? settings.to_hash : DataciteDoi.settings.to_hash,
            mappings: Doi.mappings.to_hash,
          }
        elsif name == "OtherDoi"
          {
            index_patterns: ["#{alias_name}*"],
            settings: settings.to_hash,
            mappings: Doi.mappings.to_hash,
          }
        else
          {
            index_patterns: ["#{alias_name}*"],
            settings: settings.to_hash,
            mappings: mappings.to_hash,
          }
        end

      client = Elasticsearch::Model.client
      exists = client.indices.exists_template?(name: alias_name)
      response = client.indices.put_template(name: alias_name, body: body)

      if response.to_h["acknowledged"]
        if exists
          "Updated template #{alias_name}."
        else
          "Created template #{alias_name}."
        end
      elsif exists
        "An error occured updating template #{alias_name}."
      else
        "An error occured creating template #{alias_name}."
      end
    end

    # list all templates
    def list_templates(options = {})
      client = Elasticsearch::Model.client
      cat_client = Elasticsearch::API::Cat::CatClient.new(client)
      puts cat_client.templates(name: options[:name])
    end

    # delete index template
    def delete_template
      alias_name = index_name

      client = Elasticsearch::Model.client
      if client.indices.exists_template?(name: alias_name)
        response = client.indices.delete_template(name: alias_name)

        if response.to_h["acknowledged"]
          "Deleted template #{alias_name}."
        else
          "An error occured deleting template #{alias_name}."
        end
      else
        "Template #{alias_name} does not exist."
      end
    end

    # delete from index by query
    def delete_by_query(options = {})
      return "ENV['INDEX'] is required" if options[:index].blank?
      return "ENV['QUERY'] is required" if options[:query].blank?

      client = Elasticsearch::Model.client
      response =
        client.delete_by_query(index: options[:index], body: { query: { query_string: { query: options[:query] } } })

      if response.to_h["deleted"]
        "Deleted #{response.to_h['deleted'].to_i} DOIs."
      else
        "An error occured deleting DOIs for query #{options[:query]}."
      end
    end

    def orcid_from_url(url)
      Array(%r{\A(?:(http|https)://)?(orcid\.org/)?(.+)}.match(url)).last
    end

    def ror_from_url(url)
      ror = Array(%r{\A(?:(http|https)://)?(ror\.org/)?(.+)}.match(url)).last
      "ror.org/#{ror}" if ror.present?
    end
  end
end
