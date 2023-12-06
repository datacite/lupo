# frozen_string_literal: true

class DataciteDoiSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower
  set_type :dois
  set_id :uid
  # don't cache dois, as works are cached using the doi model

  attributes :doi,
             :prefix,
             :suffix,
             :identifiers,
             :alternate_identifiers,
             :creators,
             :titles,
             :publisher,
             :container,
             :publication_year,
             :subjects,
             :contributors,
             :dates,
             :language,
             :types,
             :related_identifiers,
             :related_items,
             :sizes,
             :formats,
             :version,
             :rights_list,
             :descriptions,
             :geo_locations,
             :funding_references,
             :xml,
             :url,
             :content_url,
             :metadata_version,
             :schema_version,
             :source,
             :is_active,
             :state,
             :reason,
             :landing_page,
             :view_count,
             :views_over_time,
             :download_count,
             :downloads_over_time,
             :reference_count,
             :citation_count,
             :citations_over_time,
             :part_count,
             :part_of_count,
             :version_count,
             :version_of_count,
             :created,
             :registered,
             :published,
             :updated
  attributes :prefix,
             :suffix,
             :views_over_time,
             :downloads_over_time,
             :citations_over_time,
             if: Proc.new { |_object, params| params && params[:detail] }

  belongs_to :client, record_type: :clients
  belongs_to :provider,
             record_type: :providers,
             if: Proc.new { |_object, params| params && params[:detail] }
  has_many :media,
           record_type: :media,
           id_method_name: :uid,
           if:
             Proc.new { |_object, params|
               params && params[:detail] && !params[:is_collection]
             }
  has_many :references,
           record_type: :dois,
           serializer: DataciteDoiSerializer,
           object_method_name: :indexed_references,
           if: Proc.new { |_object, params| params && params[:detail] }
  has_many :citations,
           record_type: :dois,
           serializer: DataciteDoiSerializer,
           object_method_name: :indexed_citations,
           if: Proc.new { |_object, params| params && params[:detail] }
  has_many :parts,
           record_type: :dois,
           serializer: DataciteDoiSerializer,
           object_method_name: :indexed_parts,
           if: Proc.new { |_object, params| params && params[:detail] }
  has_many :part_of,
           record_type: :dois,
           serializer: DataciteDoiSerializer,
           object_method_name: :indexed_part_of,
           if: Proc.new { |_object, params| params && params[:detail] }
  has_many :versions,
           record_type: :dois,
           serializer: DataciteDoiSerializer,
           object_method_name: :indexed_versions,
           if: Proc.new { |_object, params| params && params[:detail] }
  has_many :version_of,
           record_type: :dois,
           serializer: DataciteDoiSerializer,
           object_method_name: :indexed_version_of,
           if: Proc.new { |_object, params| params && params[:detail] }

  attribute :xml,
            if:
              Proc.new { |_object, params|
                params && params[:detail]
              } do |object|
    Base64.strict_encode64(object.xml) if object.xml.present?
  rescue ArgumentError
    nil
  end

  attribute :doi, &:uid

  attribute :publisher do |object, params|
    # publisher accessor will now always return a publisher object, and indexed documents will store a "publisher_obj" attribute with the publisher object
    # new obj format only if ?publisher=true, otherwise serialize the old format (a string)
    publisher = object.try(:publisher_obj) || object.try(:publisher)

    return nil if publisher.nil?

    if params&.dig(:publisher) == "true"
      publisher = publisher.respond_to?(:to_hash) ? publisher : { "name" => publisher }
    else
      publisher = publisher.respond_to?(:to_hash) ? publisher["name"] : publisher
    end

    publisher
  end

  attribute :creators do |object, params|
    # Always return an array of creators and affiliations
    # use new array format only if affiliation param present
    Array.wrap(object.creators).
      map do |c|
      c["affiliation"] =
        Array.wrap(c["affiliation"]).map do |a|
          params[:affiliation] ? a : a["name"]
        end.compact
      c["nameIdentifiers"] = Array.wrap(c["nameIdentifiers"])
      c
    end.compact
  end

  attribute :contributors,
            if:
              Proc.new { |_object, params|
                params && params[:composite].blank?
              } do |object, params|
    # Always return an array of contributors and affiliations
    # use new array format only if param present
    Array.wrap(object.contributors).
      map do |c|
      c["affiliation"] =
        Array.wrap(c["affiliation"]).map do |a|
          params[:affiliation] ? a : a["name"]
        end.compact
      c["nameIdentifiers"] = Array.wrap(c["nameIdentifiers"])
      c
    end.compact
  end

  attribute :rights_list do |object|
    Array.wrap(object.rights_list)
  end

  attribute :funding_references,
            if:
              Proc.new { |_object, params|
                params && params[:composite].blank?
              } do |object|
    Array.wrap(object.funding_references)
  end

  attribute :identifiers do |object|
    Array.wrap(object.identifiers).select do |r|
      [object.doi, object.url].exclude?(r["identifier"])
    end
  end

  attribute :alternate_identifiers,
            if:
              Proc.new { |_object, params|
                params && params[:detail]
              } do |object|
    Array.wrap(object.identifiers).select do |r|
      [object.doi, object.url].exclude?(r["identifier"])
    end.map do |a|
      {
        "alternateIdentifierType" => a["identifierType"],
        "alternateIdentifier" => a["identifier"],
      }
    end.compact
  end

  attribute :related_identifiers,
            if:
              Proc.new { |_object, params|
                params && params[:composite].blank?
              } do |object|
    Array.wrap(object.related_identifiers)
  end

  attribute :related_items do |object|
    if object.related_items?
      Array.wrap(object.related_items)
    else
      []
    end
  end

  attribute :geo_locations,
            if:
              Proc.new { |_object, params|
                params && params[:composite].blank?
              } do |object|
    Array.wrap(object.geo_locations)
  end

  attribute :dates do |object|
    Array.wrap(object.dates)
  end

  attribute :subjects,
            if:
              Proc.new { |_object, params|
                params && params[:composite].blank?
              } do |object|
    Array.wrap(object.subjects)
  end

  attribute :sizes do |object|
    Array.wrap(object.sizes)
  end

  attribute :titles do |object|
    Array.wrap(object.titles)
  end

  attribute :descriptions do |object|
    Array.wrap(object.descriptions)
  end

  attribute :formats do |object|
    Array.wrap(object.formats)
  end

  attribute :container do |object|
    object.container || {}
  end

  attribute :types do |object|
    object.types || {}
  end

  attribute :state, &:aasm_state

  attribute :version, &:version_info

  attribute :published do |object|
    object.respond_to?(:published) ? object.published : nil
  end

  attribute :is_active do |object|
    object.is_active.to_s.getbyte(0) == 1
  end

  attribute :landing_page,
            if:
              Proc.new { |object, params|
                params[:current_ability] &&
                  params[:current_ability].can?(
                    :read_landing_page_results,
                    object,
                  ) ==
                    true
              },
            &:landing_page
end
