# frozen_string_literal: true

module Countable
  extend ActiveSupport::Concern

  included do
    def doi_count(
      client_id: nil, provider_id: nil, consortium_id: nil, user_id: nil
    )
      response =
        if client_id
          DataciteDoi.stats_query(client_id: client_id)
        elsif provider_id
          DataciteDoi.stats_query(provider_id: provider_id)
        elsif consortium_id
          DataciteDoi.stats_query(consortium_id: consortium_id)
        elsif user_id
          DataciteDoi.stats_query(user_id: user_id)
        else
          DataciteDoi.stats_query
        end

      if response.results.total.positive?
        facet_by_year(response.aggregations.created.buckets)
      else
        []
      end
    end

    def view_count(
      client_id: nil,
      provider_id: nil,
      consortium_id: nil,
      user_id: nil,
      state: nil
    )
      if client_id
        response =
          DataciteDoi.query(
            nil,
            client_id: client_id, page: { number: 1, size: 0 },
          )
      elsif provider_id
        response =
          DataciteDoi.query(
            nil,
            provider_id: provider_id, page: { number: 1, size: 0 },
          )
      elsif consortium_id
        response =
          DataciteDoi.query(
            nil,
            consortium_id: consortium_id, page: { number: 1, size: 0 },
          )
      elsif user_id
        response =
          DataciteDoi.query(
            nil,
            user_id: user_id, state: state, page: { number: 1, size: 0 },
          )
      else
        response = DataciteDoi.query(nil, page: { number: 1, size: 0 })
      end

      if response.results.total.positive?
        metric_facet_by_year(response.aggregations.views.buckets)
      else
        []
      end
    end

    def download_count(
      client_id: nil,
      provider_id: nil,
      consortium_id: nil,
      user_id: nil,
      state: nil
    )
      if client_id
        response =
          DataciteDoi.query(
            nil,
            client_id: client_id, page: { number: 1, size: 0 },
          )
      elsif provider_id
        response =
          DataciteDoi.query(
            nil,
            provider_id: provider_id, page: { number: 1, size: 0 },
          )
      elsif consortium_id
        response =
          DataciteDoi.query(
            nil,
            consortium_id: consortium_id, page: { number: 1, size: 0 },
          )
      elsif user_id
        response =
          DataciteDoi.query(
            nil,
            user_id: user_id, state: state, page: { number: 1, size: 0 },
          )
      else
        response = DataciteDoi.query(nil, page: { number: 1, size: 0 })
      end

      if response.results.total.positive?
        metric_facet_by_year(response.aggregations.downloads.buckets)
      else
        []
      end
    end

    def citation_count(
      client_id: nil,
      provider_id: nil,
      consortium_id: nil,
      user_id: nil,
      state: nil
    )
      if client_id
        response =
          DataciteDoi.query(
            nil,
            client_id: client_id, page: { number: 1, size: 0 },
          )
      elsif provider_id
        response =
          DataciteDoi.query(
            nil,
            provider_id: provider_id, page: { number: 1, size: 0 },
          )
      elsif consortium_id
        response =
          DataciteDoi.query(
            nil,
            consortium_id: consortium_id, page: { number: 1, size: 0 },
          )
      elsif user_id
        response =
          DataciteDoi.query(
            nil,
            user_id: user_id, state: state, page: { number: 1, size: 0 },
          )
      else
        response = DataciteDoi.query(nil, page: { number: 1, size: 0 })
      end

      if response.results.total.positive?
        metric_facet_by_year(response.aggregations.citations.buckets)
      else
        []
      end
    end

    # cumulative count clients by year
    # count until the previous year if client has been deleted
    # show all clients for admin
    def client_count(provider_id: nil, consortium_id: nil)
      if provider_id
        response =
          Client.query(
            nil,
            provider_id: provider_id,
            include_deleted: true,
            page: { number: 1, size: 0 },
          )
      elsif consortium_id
        response =
          Client.query(
            nil,
            consortium_id: consortium_id,
            include_deleted: true,
            page: { number: 1, size: 0 },
          )
      else
        response =
          Client.query(nil, include_deleted: true, page: { number: 1, size: 0 })
      end

      if response.results.total.positive?
        facet_by_cumulative_year(response.aggregations.cumulative_years.buckets)
      else
        []
      end
    end

    # count active clients by provider. Provider can only be deleted when there are no active clients.
    def active_client_count(provider_id: nil)
      return 0 if provider_id.blank?

      response =
        Client.query(
          nil,
          provider_id: provider_id, page: { number: 1, size: 0 },
        )
      response.results.total
    end

    # show provider counts for admin and consortium
    # count until the previous year if provider has been deleted
    def provider_count(consortium_id: nil)
      if consortium_id
        response =
          Provider.query(
            nil,
            consortium_id: consortium_id,
            include_deleted: true,
            page: { number: 1, size: 0 },
          )
        if response.results.total.positive?
          facet_by_cumulative_year(
            response.aggregations.cumulative_years.buckets,
          )
        else
          []
        end
      else
        response =
          Provider.query(
            nil,
            include_deleted: true, page: { number: 1, size: 0 },
          )
        if response.results.total.positive?
          facet_by_cumulative_year(
            response.aggregations.cumulative_years.buckets,
          )
        else
          []
        end
      end
    end

    def resource_type_count(
      client_id: nil,
      provider_id: nil,
      consortium_id: nil,
      user_id: nil,
      state: nil
    )
      if client_id
        response =
          DataciteDoi.query(
            nil,
            client_id: client_id, page: { number: 1, size: 0 },
          )
      elsif provider_id
        response =
          DataciteDoi.query(
            nil,
            provider_id: provider_id, page: { number: 1, size: 0 },
          )
      elsif consortium_id
        response =
          DataciteDoi.query(
            nil,
            consortium_id: consortium_id, page: { number: 1, size: 0 },
          )
      elsif user_id
        response =
          DataciteDoi.query(
            nil,
            user_id: user_id, state: state, page: { number: 1, size: 0 },
          )
      else
        response = DataciteDoi.query(nil, page: { number: 1, size: 0 })
      end

      if response.results.total.positive?
        facet_by_combined_key(response.aggregations.resource_types.buckets)
      else
        []
      end
    end
  end
end
