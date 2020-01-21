module MetricsHelper
  extend ActiveSupport::Concern

  included do

    def get_metrics_array(dois)

      citations   = EventsQuery.new.citations(dois)
      views       = EventsQuery.new.views(dois)
      downloads   = EventsQuery.new.downloads(dois)

      first_merge = merge_array_hashes(citations, views)
      merge_array_hashes(first_merge, downloads)
    end

    def merge_array_hashes(first_array, second_array)
      return first_array if second_array.blank?
      return second_array if first_array.blank?

      total = first_array | second_array
      total.group_by {|hash| hash[:id]}.map do |key, value|
        metrics = value.reduce(&:merge)
        {id: key}.merge(metrics)
      end
    end
  end

  class_methods do 
    # def doi_citations(doi)
    #   EventsQuery.new.citations(doi)
    # end

    # def doi_views(doi)
    #   EventsQuery.new.doi_views(doi)
    # end

    # def doi_downloads(doi)
    #   EventsQuery.new.doi_downloads(doi)
    # end

    def mix_in_metrics(doi, metrics_array_hashes)
      metrics_array_hashes.select { |hash| hash[:id] == doi }.first
    end
  end
end
