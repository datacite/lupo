module Paginatable
  extend ActiveSupport::Concern

  included do
    # make sure page parameter is a hash with keys size, number and/or cursor
    def page_from_params(params)
      p = params.to_unsafe_h.dig(:page)

      if p.is_a?(Hash)
        page = {
          size: p["size"],
          number: p["number"],
          cursor: p["cursor"]
        }.compact
      else
        page = {}
      end

      # All cursors will need to be decoded from the param
      if page[:cursor].present?
        begin
          # When we decode and split, we'll always end up with an array
          page[:cursor] = Base64.strict_decode64(page[:cursor]).split(",")
        rescue ArgumentError
          raise "Invalid base64 used for cursor pased from query params"
        end
      end

      if page[:size].present?
        page[:size] = [page[:size].to_i, 10000].min
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
