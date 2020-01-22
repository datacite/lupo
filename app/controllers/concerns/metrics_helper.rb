module MetricsHelper
  extend ActiveSupport::Concern
  include Helpable

  included do

    def get_metrics_array(dois)

      citations   = EventsQuery.new.citations(dois)
      views       = EventsQuery.new.views(dois)
      downloads   = EventsQuery.new.downloads(dois)

      first_merge = merge_array_hashes(citations, views)
      merge_array_hashes(first_merge, downloads)
    end
  end

  class_methods do 
    def mix_in_metrics(doi, metrics_array_hashes)
      metrics_array_hashes.select { |hash| hash[:id] == doi }.first
    end
  end
end
