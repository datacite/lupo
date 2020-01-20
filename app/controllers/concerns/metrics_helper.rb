module MetricsHelper
  extend ActiveSupport::Concern

  class_methods do
    def doi_citations(doi)
      EventsQuery.new.doi_citations(doi)
    end

    def doi_views(doi)
      EventsQuery.new.doi_views(doi)
    end

    def doi_downloads(doi)
      EventsQuery.new.doi_downloads(doi)
    end
  end
end
