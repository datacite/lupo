# frozen_string_literal: true

class EnrichedDoiSerializer < DataciteDoiSerializer
  set_type :enriched_dois

  has_many :enrichments,
           record_type: :enrichments,
           serializer: EnrichmentSerializer,
           id_method_name: :enrichment_uuids
end
