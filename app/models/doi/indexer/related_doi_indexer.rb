# frozen_string_literal: true

module Doi::Indexer
  class RelatedDoiIndexer
    def initialize(related_identifiers)
      @related_identifiers = related_identifiers
      @related_dois = nil
    end

    def related_dois
      @related_dois ||= @related_identifiers.select { |r| r["relatedIdentifierType"] == "DOI" }
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
