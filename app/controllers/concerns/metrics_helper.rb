require "pp"
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
      Event.query(nil, page: { size: 300 }, source_id: "datacite-orcid-auto-update", obj_id: "https://orcid.org/#{orcid}").results.to_a.map do |e|
        doi_from_url(e.subj_id)
      end
    end

    def mix_in_metrics_array(metadata_array_objects, metrics_array_hashes)
      return [] if metadata_array_objects.empty?

      metadata_array_objects.map do |metadata|
        metadata_hash = metadata.to_hash
        metrics = metrics_array_hashes.select { |hash| hash[:id] == metadata_hash["_source"]["uid"] }.first
        Hashie::Mash.new(metadata_hash)._source.shallow_update(metrics)
      end
    end

    def mix_in_metrics(metadata, metrics)
      metadata_hash = metadata.attributes
      metrics[:doi] = metrics.delete :id
      metrics[:uid] = metrics[:doi]
      metrics[:doi] = metrics[:doi].upcase
      metadata_hash.merge!(metrics)
      Hashie::Mash.new(metadata_hash)
    end
  end

  # class_methods do
  #   # def mix_in_metrics(doi, metrics_array_hashes)
  #   #   metrics_array_hashes.select { |hash| hash[:id] == doi }.first
  #   # end
  # end
end
