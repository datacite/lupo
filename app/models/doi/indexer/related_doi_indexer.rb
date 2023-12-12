# frozen_string_literal: true

module Doi::Indexer
  class RelatedDoiIndexer
    REQUIRED_KEYS = %w[
      relatedIdentifier
      relatedIdentifierType
      relationType
    ]

    def initialize(related_identifiers)
      @related_identifiers = Array.wrap(related_identifiers)
      @related_dois = nil
    end

    def is_related_doi?(related)
      related.is_a?(Hash) &&
        REQUIRED_KEYS.all? { |k| related.key?(k) } &&
        related.fetch("relatedIdentifierType", nil) == "DOI"
    end

    def related_dois
      @related_dois ||= @related_identifiers.select do |r|
        is_related_doi?(r)
      end
    end

    def related_grouped_by_id
      related_dois.group_by { |r| r["relatedIdentifier"].downcase }
    end

    def relation_types_gouped_by_id
      related_grouped_by_id.transform_values do |values|
        values.map { |val| val["relationType"].underscore }.uniq
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
      rtypes = relation_types_gouped_by_id
      indexed_dois.map do |indexed_doi|
        doi = indexed_doi["doi"]
        indexed_doi["relation_type"] = rtypes[doi]
        indexed_doi
      end
    end
  end
end
