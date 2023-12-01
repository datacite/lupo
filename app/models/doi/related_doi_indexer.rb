# frozen_string_literal: true

module Doi::Indexer
  class RelatedDoiIndexer
    def initialize(related_identifiers)
      @related_identifiers = related_identifiers
      @related_dois = []
    end

    def related_dois
      @related_dois ||= @related_identifiers.select { |r| r["relatedIdentifierType"] == "DOI" }
    end

    def related_grouped_by_id
      related_dois.group_by{ |r| r[:relatedIdentifier].downcase }
    end

    def relation_types_gouped_by_id
      related_grouped_by_id.transform_values do |values|
        values.map{ |val| val[:relationType] }.uniq
      end
    end

    def related_doi_ids
      related_grouped_by_id.keys
    end

    def dois
      Doi.where(doi: related_doi_ids)
    end

    def indexed_dois
      dois.map { |d| RelatedIdentifierDenormalizer.new(d).to_hash }
    end

    def as_indexed_json
      indexed_dois
    end
  end
end

