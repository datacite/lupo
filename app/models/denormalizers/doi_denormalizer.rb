# frozen_string_literal: true

module Denormalizers
  class DoiDenormalizer
    attr_reader :doi
  
    def initialize(doi)
      @doi = doi
    end
  
    def to_hash
      %w[
        id
        uid
        doi
        identifier
        url
        creators
        contributors
        creators_and_contributors
        creator_names
        titles
        descriptions
        publisher
        client_id
        provider_id
        consortium_id
        resource_type_id
        person_id
        client_id_and_name
        provider_id_and_name
        resource_type_id_and_name
        affiliation_id
        fair_affiliation_id
        organization_id
        fair_organization_id
        related_dmp_organization_id
        affiliation_id_and_name
        fair_affiliation_id_and_name
        media_ids
        view_count
        views_over_time
        download_count
        downloads_over_time
        citation_count
        citations_over_time
        reference_count
        part_count
        part_of_count
        version_count
        version_of_count
        prefix
        suffix
        types
        identifiers
        related_identifiers
        related_items
        funding_references
        publication_year
        dates
        geo_locations
        rights_list
        container
        content_url
        version_info
        formats
        sizes
        language
        subjects
        fields_of_science
        fields_of_science_repository
        fields_of_science_combined
        xml
        is_active
        landing_page
        agency
        aasm_state
        schema_version
        metadata_version
        reason
        source
        cache_key
        registered
        created
        updated
        published
        client
        provider
        resource_type
        media
        reference_ids
        citation_ids
        part_ids
        part_of_ids
        version_ids
        version_of_ids
        primary_title
        publisher_obj
      ].map { |method_name| [method_name, send(method_name)] }.to_h
    end
  
    def id
      34
    end
  end
end