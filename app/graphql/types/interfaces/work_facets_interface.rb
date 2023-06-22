# frozen_string_literal: true

module Interfaces::WorkFacetsInterface
  include BaseInterface
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true

  field :published, [FacetType], null: true, cache: true
  field :open_license_resource_types, [FacetType], null: true, cache: true
  field :registration_agencies, [FacetType], null: true, cache: true
  field :repositories, [FacetType], null: true, cache: true
  field :affiliations, [FacetType], null: true, cache: true
  field :authors, [FacetType], null: true, cache: true
  field :creators_and_contributors, [FacetType], null: true, cache: true
  field :fields_of_science, [FacetType], null: true, cache: true
  field :fields_of_science_combined, [FacetType], null: true, cache: true
  field :fields_of_science_repository, [FacetType], null: true, cache: true
  field :licenses, [FacetType], null: true, cache: true
  field :languages, [FacetType], null: true, cache: true

  def total_count
    object.total_count
  end

  def published
    if object.aggregations.published
      facet_by_range(object.aggregations.published.buckets)
    else
      []
    end
  end

  def open_license_resource_types
    if object.aggregations.open_licenses
      facet_by_combined_key(object.aggregations.open_licenses.resource_types.buckets)
    else
      []
    end
  end

  def registration_agencies
    if object.aggregations.registration_agencies
      facet_by_registration_agency(
        object.aggregations.registration_agencies.buckets
      )
    else
      []
    end
  end

  def repositories
    if object.aggregations.clients
      facet_by_combined_key(object.aggregations.clients.buckets)
    else
      []
    end
  end

  def affiliations
    if object.aggregations.affiliations
      arr = facet_by_combined_key(object.aggregations.affiliations.buckets)
      add_other(arr, object.aggregations.affiliations.sum_other_doc_count)
    else
      []
    end
  end

  def authors
    if object.aggregations.authors
      facet_by_authors(object.aggregations.authors.buckets)
    else
      []
    end
  end

  def creators_and_contributors
    if object.aggregations.creators_and_contributors
      facet_by_creators_and_contributors(object.aggregations.creators_and_contributors.buckets)
    else
      []
    end
  end

  def licenses
    if object.aggregations.licenses
      arr = facet_by_license(object.aggregations.licenses.buckets)
      add_other(arr, object.aggregations.licenses.sum_other_doc_count)
    else
      []
    end
  end

  def fields_of_science
    if object.aggregations.fields_of_science
      facet_by_fos(object.aggregations.fields_of_science.subject.buckets)
    else
      []
    end
  end

  def fields_of_science_combined
    if object.aggregations.fields_of_science_combined
      facet_by_fos(object.aggregations.fields_of_science_combined.buckets)
    else
      []
    end
  end

  def fields_of_science_repository
    if object.aggregations.fields_of_science_repository
      facet_by_fos(object.aggregations.fields_of_science_repository.buckets)
    else
      []
    end
  end

  def languages
    if object.aggregations.languages
      facet_by_language(object.aggregations.languages.buckets)
    else
      []
    end
  end
end
