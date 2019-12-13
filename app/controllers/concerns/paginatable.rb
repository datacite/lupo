module Paginatable
  extend ActiveSupport::Concern

  included do
    # make sure page parameter is a hash with keys size, number and/or cursor
    def page_from_params(params)
      p = params.to_unsafe_h.dig(:page)

      if p.is_a?(Hash)
        page = p.symbolize_keys
      else
        page = {}
      end

      # Use scroll API for large number of results, e.g. to generate sitemaps      
      # Alternatively use cursor
      # All cursors will need to be decoded from the param
      # Check for presence of :cursor key, value can be empty
      if page.has_key?(:cursor) && !page.has_key?(:scroll)
        begin
          # When we decode and split, we'll always end up with an array
          # use urlsafe_decode to not worry about url-unsafe characters + and /
          # split into two strings so that DOIs with comma in them are left intact
          page[:cursor] = Base64.urlsafe_decode64(page[:cursor].to_s).split(",", 2)
        rescue ArgumentError
          # If we fail to decode we'll just default back to an empty cursor
          page[:cursor] = []
        end
      end

      # Elasticsearch is limited to 10000 results per query, so we liit with max_number
      # max number of results per page is 1000
      if page[:size].present?
        page[:size] = [page[:size].to_i, 1000].min
        max_number = page[:size] > 0 ? 10000/page[:size] : 1
      else
        page[:size] = 25
        max_number = 10000/page[:size]
      end
      page[:number] = page[:number].to_i > 0 ? [page[:number].to_i, max_number].min : 1

      page
    end

    def make_cursor(results)
      # Base64-encode cursor
      Base64.urlsafe_encode64(results.to_a.last[:sort].join(","), padding: false)
    end
  end
end
