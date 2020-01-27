module MetricsHelper
  extend ActiveSupport::Concern
  include Helpable

  included do
    def get_metrics_array(dois)
      citations = EventsQuery.new.citations(dois)
      usage = EventsQuery.new.views_and_downloads(dois)
      merge_array_hashes(citations, usage)
    end

    def get_person_metrics(orcid)
      dois = get_person_dois(orcid).join(",")
      usage = EventsQuery.new.views_and_downloads(dois)
      {
        citations: EventsQuery.new.citations(dois).sum { |h| h[:citations] },
        views: usage.sum { |h| h[:views] },
        downloads: usage.sum { |h| h[:downloads] },
      }
    end

    def get_person_dois(orcid)
      Event.query(nil, page: { size: 500 }, obj_id: https_to_http(orcid)).results.to_a.map do |e|
        doi_from_url(e.subj_id)
      end
    end

    def https_to_http(url)
      orcid = orcid_from_url(url)
      return nil if orcid.blank?

      "https://orcid.org/#{orcid}"
    end

    def mix_in_metrics(metadata_array_objects, metrics_array_hashes)
      metadata_array_objects.map do |metadata|
        metadata_hash = metadata.to_hash
        metrics = metrics_array_hashes.select { |hash| hash[:id] == metadata_hash.doi }.first
        Hashie::Mash.new(metrics).shallow_merge(metadata_hash)
      end
    end
  end

  class_methods do
    def mix_in_metrics(doi, metrics_array_hashes)
      metrics_array_hashes.select { |hash| hash[:id] == doi }.first
    end
  end
end
