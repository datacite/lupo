# frozen_string_literal: true

class EventConnectionWithTotalType < BaseConnection
  edge_type(EventEdgeType)

  field :total_count, Integer, null: false
  field :published, [FacetType], null: true
  field :registration_agencies, [FacetType], null: true
  field :repositories, [FacetType], null: true
  field :affiliations, [FacetType], null: true
  field :fields_of_science, [FacetType], null: true
  field :licenses, [FacetType], null: true
  field :languages, [FacetType], null: true

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
      facet_by_combined_key(object.aggregations.affiliations.buckets)
    else
      []
    end
  end

  def licenses
    if object.aggregations.licenses
      facet_by_license(object.aggregations.licenses.buckets)
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

  def languages
    if object.aggregations.languages
      facet_by_language(object.aggregations.languages.buckets)
    else
      []
    end
  end
end
