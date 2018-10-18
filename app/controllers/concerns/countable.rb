module Countable
  extend ActiveSupport::Concern

  included do
    def doi_count(client_id: nil, provider_id: nil)
      if client_id
        response = Doi.query(nil, client_id: client_id, page: { number: 1, size: 0 })
      elsif provider_id
        response = Doi.query(nil, provider_id: provider_id, page: { number: 1, size: 0 })
      else
        response = Doi.query(nil, page: { number: 1, size: 0 })
      end

      response.results.total > 0 ? facet_by_year(response.response.aggregations.created.buckets) : nil
    end

    # cumulative count clients by year
    # count until the previous year if client has been deleted
    # show all clients for admin
    def client_count(provider_id: nil)
      if provider_id
        response = Client.query(nil, provider_id: provider_id, include_deleted: true, page: { number: 1, size: 0 })
      else
        response = Client.query(nil, page: { number: 1, size: 0 })
      end

      response.results.total > 0 ? facet_by_cumuative_year(response.response.aggregations.cumulative_years.buckets) : nil
    end

    # show provider count for admin
    # count until the previous year if provider has been deleted
    def provider_count(provider_id: nil)
      return nil if provider_id 

      response = Provider.query(nil, page: { number: 1, size: 0 })
      response.results.total > 0 ? facet_by_cumuative_year(response.response.aggregations.cumulative_years.buckets) : nil
    end
  end
end
