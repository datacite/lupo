# frozen_string_literal: true

module Doi::Indexer
  class RelatedIdentifierDenormalizer
    attr_reader :related_doi

    def initialize(doi)
      @related_doi = doi
    end

    def to_hash
      %w[
        client_id
        doi
        organization_id
        person_id
        resource_type_id
        resource_type_id_and_name
      ].index_with { |method_name| send(method_name) }
    end

    delegate :resource_type_id, to: :related_doi
    delegate :resource_type_id_and_name, to: :related_doi
    delegate :organization_id, to: :related_doi
    delegate :person_id, to: :related_doi
    delegate :client_id, to: :related_doi

    def doi
      @related_doi.doi.downcase
    end
  end
end
