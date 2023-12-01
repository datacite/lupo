# frozen_string_literal: true

module Doi::Indexer
  class RelatedIdentifierDenormalizer
    attr_reader :related_doi

    def initialize(doi)
      @related_doi = doi
    end

    def to_hash
      %w[
        resource_type_id
        doi
        organization_id
      ].index_with { |method_name| send(method_name) }
    end

    delegate :resource_type_id, to: :related_doi
    delegate :organization_id, to: :related_doi

    def doi
      @related_doi.doi.downcase
    end
  end
end

