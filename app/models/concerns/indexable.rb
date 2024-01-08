# frozen_string_literal: true

module Indexable
  extend ActiveSupport::Concern

  require "aws-sdk-sqs"

  included do
    after_commit on: %i[create update] do
      Rails.logger.info "[Event Data Import Message] After commit"
      # use index_document instead of update_document to also update virtual attributes
      unless %w[Prefix ProviderPrefix ClientPrefix].include?(self.class.name)
        IndexJob.perform_later(self)
      else
        __elasticsearch__.index_document
        # This is due to the order of indexing, we want to always ensure
        # the prefix index is up to date with relations
        # So we force it here to reindex prefix if we touch them.
        if ["ProviderPrefix", "ClientPrefix"].include?(self.class.name)
          self.prefix.__elasticsearch__.index_document
        end
      end

      if instance_of?(DataciteDoi) || instance_of?(OtherDoi) || instance_of?(Doi)
        Rails.logger.info "[Event Data Import Message] #{aasm_state} #{to_jsonapi.inspect} its a DOI"
        if aasm_state == "findable"
          changed_attributes = saved_changes
          Rails.logger.info "[Event Data Import Message] #{aasm_state} #{changed_attributes.inspect} before call"
          relevant_changes = changed_attributes.keys & %w[related_identifiers creators funding_references aasm_state]
          if relevant_changes.any?
            send_import_message(to_jsonapi)
            Rails.logger.info "[Event Data Import Message] #{aasm_state} #{to_jsonapi.inspect} send to Event Data service."
          end
        end
      elsif instance_of?(Event)
        OtherDoiJob.perform_later(dois_to_import)
      # ignore if record was created via Salesforce API
      elsif instance_of?(Provider) && !from_salesforce && (Rails.env.production? || ENV["ES_PREFIX"] == "stage")
        send_provider_export_message(to_jsonapi.merge(slack_output: true))
      elsif instance_of?(Client) && !from_salesforce && (Rails.env.production? || ENV["ES_PREFIX"] == "stage")
        send_client_export_message(to_jsonapi.merge(slack_output: true))
      elsif instance_of?(Contact) && !from_salesforce && (Rails.env.production? || ENV["ES_PREFIX"] == "stage")
        send_contact_export_message(to_jsonapi.merge(slack_output: true))
      end
    end

    after_touch do
      # prefixes need to be reindexed sooner
      if ["Prefix", "ProviderPrefix", "ClientPrefix"].include?(self.class.name)
        __elasticsearch__.index_document
      else
        IndexBackgroundJob.perform_later(self)
      end
    end

    after_commit on: [:destroy] do
      begin
        __elasticsearch__.delete_document
        if self.class.name == "Event"
          Rails.logger.warn "#{self.class.name} #{uuid} deleted from Elasticsearch index."
        else
          Rails.logger.warn "#{self.class.name} #{uid} deleted from Elasticsearch index."
        end
        # send_delete_message(self.to_jsonapi) if self.class.name == "Doi" && !Rails.env.test?

        # reindex prefix
        if ["ProviderPrefix", "ClientPrefix"].include?(self.class.name)
          IndexJob.perform_later(self.prefix)
        end
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
        Rails.logger.error e.message
      end
      if instance_of?(Event)
        Rails.logger.info "#{self.class.name} #{
                              uuid
                            } deleted from Elasticsearch index."
      else
        Rails.logger.info "#{self.class.name} #{
                              uid
                            } deleted from Elasticsearch index."
      end
      # send_delete_message(self.to_jsonapi) if self.class.name == "Doi" && !Rails.env.test?
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      Rails.logger.error e.message
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
    # we use the AWS SQS client directly as there is no consumer in this app
    def send_message(body, options = {})
      sqs = Aws::SQS::Client.new
      queue_name_prefix =
        if Rails.env.stage?
          ENV["ES_PREFIX"].present? ? "stage" : "test"
        else
          Rails.env
        end
      queue_url =
        sqs.get_queue_url(queue_name: "#{queue_name_prefix}_#{options[:queue_name]}").queue_url
      options[:shoryuken_class] ||= "DoiImportWorker"

      options = {
        queue_url: queue_url,
        message_attributes: {
          "shoryuken_class" => {
            string_value: options[:shoryuken_class], data_type: "String"
          },
        },
        message_body: body.to_json,
      }

      sqs.send_message(options)
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
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
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
          filter << { term: { region: options[:region].upcase } }
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
      index_name = options[:index] || self.index_name + "_v1"
      # alternate_index_name = options[:index] || self.index_name + "_v2"

      client = Elasticsearch::Model.client

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_index_name])
      #     "Alias #{alias_name} for index #{datacite_index_name} already exists."
      #   else
      #     client.indices.put_alias index: datacite_index_name, name: alias_name
      #     "Created alias #{alias_name} for index #{datacite_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_index_name])
      #     "Alias #{alias_name} for index #{other_index_name} already exists."
      #   else
      #     client.indices.put_alias index: other_index_name, name: alias_name
      #     "Created alias #{alias_name} for index #{other_index_name}."
      #   end
      # else
      if client.indices.exists_alias?(name: alias_name, index: [index_name])
        "Alias #{alias_name} for index #{index_name} already exists."
      else
        # alias index is writeable unless it is for OtherDoi index
        client.indices.update_aliases(
          body: {
            actions: [
              {
                add: {
                  index: index_name,
                  alias: alias_name,
                  is_write_index: name != "OtherDoi",
                },
              },
            ],
          },
        )

        "Created alias #{alias_name} for index #{index_name}."
      end
      # end
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
      index_name = (options[:index] || self.index_name) + "_v1"
      alternate_index_name = (options[:index] || self.index_name) + "_v2"

      client = Elasticsearch::Model.client

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_index_name])
      #     client.indices.delete_alias index: datacite_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{datacite_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_alternate_index_name])
      #     client.indices.delete_alias index: datacite_alternate_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{datacite_alternate_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_index_name])
      #     client.indices.delete_alias index: other_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{other_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_alternate_index_name])
      #     client.indices.delete_alias index: other_alternate_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{other_alternate_index_name}."
      #   end
      # else
      if client.indices.exists_alias?(name: alias_name, index: [index_name])
        client.indices.delete_alias index: index_name, name: alias_name
        "Deleted alias #{alias_name} for index #{index_name}."
      end
      if client.indices.exists_alias?(
        name: alias_name, index: [alternate_index_name],
      )
        client.indices.delete_alias index: alternate_index_name,
                                    name: alias_name
        "Deleted alias #{alias_name} for index #{alternate_index_name}."
      end
      # end
    end

    # create both indexes used for aliasing
    def create_index(options = {})
      alias_name = options[:alias] || index_name
      index_name = (options[:index] || self.index_name) + "_v1"
      alternate_index_name = (options[:index] || self.index_name) + "_v2"
      client = Elasticsearch::Model.client

      # delete index if it has the same name as the alias
      if __elasticsearch__.index_exists?(index: alias_name) &&
          !client.indices.exists_alias?(name: alias_name)
        __elasticsearch__.delete_index!(index: alias_name)
      end

      create_template if name == "DataciteDoi" || name == "OtherDoi"

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   self.__elasticsearch__.create_index!(index: datacite_index_name) unless self.__elasticsearch__.index_exists?(index: datacite_index_name)
      #   self.__elasticsearch__.create_index!(index: datacite_alternate_index_name) unless self.__elasticsearch__.index_exists?(index: datacite_alternate_index_name)
      #   self.__elasticsearch__.create_index!(index: other_index_name) unless self.__elasticsearch__.index_exists?(index: other_index_name)
      #   self.__elasticsearch__.create_index!(index: other_alternate_index_name) unless self.__elasticsearch__.index_exists?(index: other_alternate_index_name)

      #   "Created indexes #{datacite_index_name}, #{other_index_name}, #{datacite_alternate_index_name}, and #{other_alternate_index_name}."
      # else
      unless __elasticsearch__.index_exists?(index: index_name)
        __elasticsearch__.create_index!(index: index_name)
      end
      unless __elasticsearch__.index_exists?(index: alternate_index_name)
        __elasticsearch__.create_index!(index: alternate_index_name)
      end

      "Created indexes #{index_name} and #{alternate_index_name}."
      # end
    end

    # delete index and both indexes used for aliasing
    def delete_index(options = {})
      # client = Elasticsearch::Model.client

      if options[:index]
        __elasticsearch__.delete_index!(index: options[:index])
        return "Deleted index #{options[:index]}."
      end

      # alias_name = index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   self.__elasticsearch__.delete_index!(index: datacite_index_name) if self.__elasticsearch__.index_exists?(index: datacite_index_name)
      #   self.__elasticsearch__.delete_index!(index: datacite_alternate_index_name) if self.__elasticsearch__.index_exists?(index: datacite_alternate_index_name)
      #   self.__elasticsearch__.delete_index!(index: other_index_name) if self.__elasticsearch__.index_exists?(index: other_index_name)
      #   self.__elasticsearch__.delete_index!(index: other_alternate_index_name) if self.__elasticsearch__.index_exists?(index: other_alternate_index_name)

      #   "Deleted indexes #{datacite_index_name}, #{other_index_name}, #{datacite_alternate_index_name}, and #{other_alternate_index_name}."
      # else
      if __elasticsearch__.index_exists?(index: index_name)
        __elasticsearch__.delete_index!(index: index_name)
      end
      if __elasticsearch__.index_exists?(index: alternate_index_name)
        __elasticsearch__.delete_index!(index: alternate_index_name)
      end

      "Deleted indexes #{index_name} and #{alternate_index_name}."
      # end
    end

    # list all indices
    def list_indices
      client = Elasticsearch::Model.client
      cat_client = Elasticsearch::API::Cat::CatClient.new(client)
      puts cat_client.indices(s: "index")
    end

    # delete and create inactive index to use current mappings
    # Needs to run every time we change the mappings
    def upgrade_index(options = {})
      inactive_index ||= (options[:index] || self.inactive_index)

      __elasticsearch__.create_index!(index: inactive_index, force: true)
      "Upgraded inactive index #{inactive_index}."
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

    # switch between the two indexes, i.e. the index that is aliased
    # alias index for OtherDoi by default is not writeable,
    # as we also have DataciteDoi alias
    def switch_index(options = {})
      alias_name = options[:alias] || index_name
      index_name = (options[:index] || self.index_name) + "_v1"
      alternate_index_name = (options[:index] || self.index_name) + "_v2"
      is_write_index = options[:is_write_index] || name != "OtherDoi"

      client = Elasticsearch::Model.client

      if client.indices.exists_alias?(name: alias_name, index: [index_name])
        client.indices.update_aliases body: {
          actions: [
            {
              remove: {
                index: index_name,
                alias: alias_name,
              },
            },
            {
              add: {
                index: alternate_index_name,
                alias: alias_name,
                is_write_index: is_write_index,
              },
            },
          ],
        }

        "Switched active index to #{alternate_index_name}."
      elsif client.indices.exists_alias?(
        name: alias_name, index: [alternate_index_name],
      )
        client.indices.update_aliases body: {
          actions: [
            {
              remove: {
                index: alternate_index_name,
                alias: alias_name,
              },
            },
            {
              add: {
                index: index_name,
                alias: alias_name,
                is_write_index: is_write_index,
              },
            },
          ],
        }

        "Switched active index to #{index_name}."
      end

      # TODO switch to DataCiteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: datacite_index_name, alias: alias_name } },
      #         { add:    { index: datacite_alternate_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{datacite_alternate_index_name}."
      #   elsif client.indices.exists_alias?(name: alias_name, index: [datacite_alternate_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: datacite_alternate_index_name, alias: alias_name } },
      #         { add:    { index: datacite_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index  for alias #{alias_name} to #{datacite_index_name}."
      #   end

      #   if client.indices.exists_alias?(name: alias_name, index: [other_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: other_index_name, alias: alias_name } },
      #         { add:    { index: other_alternate_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{other_alternate_index_name}."
      #   elsif client.indices.exists_alias?(name: alias_name, index: [other_alternate_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: other_alternate_index_name, alias: alias_name } },
      #         { add:    { index: other_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{other_index_name}."
      #   end
      # elsif self.name == "DataciteDoi" || self.name == "OtherDoi"
      #   if client.indices.exists_alias?(name: alias_name, index: [index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: index_name, alias: alias_name } },
      #         { remove: { index: index_name, alias: Doi.index_name } },
      #         { add:    { index: alternate_index_name, alias: alias_name } },
      #         { add:    { index: alternate_index_name, alias: Doi.index_name } }
      #       ]
      #     }

      #     "Switched active index for aliases #{alias_name} and #{Doi.index_name} to #{alternate_index_name}."
      #   elsif client.indices.exists_alias?(name: alias_name, index: [alternate_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: alternate_index_name, alias: alias_name } },
      #         { remove: { index: alternate_index_name, alias: Doi.index_name } },
      #         { add:    { index: index_name, alias: alias_name } },
      #         { add:    { index: index_name, alias: Doi.index_name } }
      #       ]
      #     }

      #     "Switched active index for aliases #{alias_name} and #{Doi.index_name} to #{index_name}."
      #   end
      # else
      #   if client.indices.exists_alias?(name: alias_name, index: [index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: index_name, alias: alias_name } },
      #         { add:    { index: alternate_index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{alternate_index_name}."
      #   elsif client.indices.exists_alias?(name: alias_name, index: [alternate_index_name])
      #     client.indices.update_aliases body: {
      #       actions: [
      #         { remove: { index: alternate_index_name, alias: alias_name } },
      #         { add:    { index: index_name, alias: alias_name } }
      #       ]
      #     }

      #     "Switched active index for alias #{alias_name} to #{index_name}."
      #   end
      # end
    end

    # Return the active index, i.e. the index that is aliased
    # Don't rely on the first index being the correct one.
    def active_index
      ret = nil

      alias_name = index_name
      client = Elasticsearch::Model.client

      begin
        h = client.indices.get_alias(name: alias_name)

        if h.size == 1
          ret = h.keys.first
        else
          # Looping through indices that have alias_name.
          h.each do |key, value|
            if value.dig("aliases", alias_name, "is_write_index") == true
              ret = key
              break
            end
          end
          # If it gets here with no value, just return the first key.
          if ret.nil?
            ret = h.keys.first
          end
        end
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
        Rails.logger.error e.message
      end

      ret
    end

    # Return the inactive index, i.e. the index that is not aliased
    def inactive_index
      ret = nil

      active_index = self.active_index

      if !active_index.nil?
        index_name = self.index_name + "_v1"
        alternate_index_name = self.index_name + "_v2"

        ret = active_index.end_with?("v1") ? alternate_index_name : index_name
      end

      ret
    end

    # create index template
    def create_template
      alias_name = index_name

      body =
        if name == "Doi" || name == "DataciteDoi" || name == "OtherDoi"
          {
            index_patterns: %w[dois*],
            settings: Doi.settings.to_hash,
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
