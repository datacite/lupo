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

    def get_person_metrics(orcid)
      dois = get_person_dois(orcid)
      {
        citations: EventsQuery.new.citations(dois.join(",")).sum { |h| h[:citations] },
        views: EventsQuery.new.views(dois.join(",")).sum { |h| h[:views] },
        downloads: EventsQuery.new.downloads(dois.join(",")).sum { |h| h[:downloads] }
      }
    end

    def get_person_dois(orcid)
      Event.query(nil, page: { size: 500 }, obj_id: https_to_http(orcid)).results.to_a.map do |e|
        doi_from_url(e.subj_id)
      end
    end
  
    def https_to_http(url)
      orcid = orcid_from_url(url)
      return nil unless orcid.present?
  
      "https://orcid.org/#{orcid}"
    end

  end

  class_methods do 
    def mix_in_metrics(doi, metrics_array_hashes)
      metrics_array_hashes.select { |hash| hash[:id] == doi }.first
    end
  end
end
