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