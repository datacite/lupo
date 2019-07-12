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

      # All cursors will need to be decoded from the param
      # Check for presence of :cursor key, value can be empty
      if page.has_key?(:cursor)
        begin
          # When we decode and split, we'll always end up with an array
          # use urlsafe_decode to not worry about url-unsafe characters + and /
          page[:cursor] = Base64.urlsafe_decode64(page[:cursor].to_s).split(",")
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
  end
end
