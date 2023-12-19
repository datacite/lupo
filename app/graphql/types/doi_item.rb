# frozen_string_literal: true

module DoiItem
  include BaseInterface
  include Bolognese::MetadataUtils

  REGISTRATION_AGENCIES = {
    "airiti" => "Airiti",
    "cnki" => "CNKI",
    "crossref" => "Crossref",
    "datacite" => "DataCite",
    "istic" => "ISTIC",
    "jalc" => "JaLC",
    "kisti" => "KISTI",
    "medra" => "mEDRA",
    "op" => "OP",
  }.freeze

  class CitationFormat < GraphQL::Schema::Enum
    description "Citation formats"
    value :html
    value :text
  end



  description "Information about DOIs"

  field :id,
        ID,
        null: false,
        hash_key: "identifier",
        description: "The persistent identifier for the resource"
  field :type, String, null: false, description: "The type of the item."
  field :doi,
        String,
        null: false, hash_key: "uid", description: "The DOI for the resource."
  field :creators,
        [CreatorType],
        null: true,
        description:
          "The main researchers involved in producing the data, or the authors of the publication, in priority order." do
    argument :first, Int, required: false, default_value: 20
  end
  field :contributors,
        [ContributorType],
        null: true,
        description:
          "The institution or person responsible for collecting, managing, distributing, or otherwise contributing to the development of the resource." do
    argument :first, Int, required: false, default_value: 20
    argument :contributor_type, String, required: false
  end
  field :titles,
        [TitleType],
        null: true,
        description: "A name or title by which a resource is known." do
    argument :first, Int, required: false, default_value: 5
  end
  field :publication_year,
        Int,
        null: true,
        description:
          "The year when the data was or will be made publicly available"
  field :publisher,
        PublisherType,
        null: true,
        description:
          "The entity that holds, archives, publishes prints, distributes, releases, issues, or produces the resource"
  field :subjects,
        [SubjectType],
        null: true,
        description:
          "Subject, keyword, classification code, or key phrase describing the resource"
  field :fields_of_science,
        [FieldOfScienceType],
        null: true, description: "OECD Fields of Science of the resource"

  field :fields_of_science_combined,
        [FieldOfScienceType],
        null: true, description: "OECD Fields of Science of the resource and containing repository"

  field :fields_of_science_repository,
        [FieldOfScienceType],
        null: true, description: "OECD Fields of Science of the containing repository"

  field :dates,
        [DateType],
        null: true, description: "Different dates relevant to the work"
  field :registered,
        GraphQL::Types::ISO8601DateTime,
        null: true, description: "DOI registration date"
  field :language,
        LanguageType,
        null: true, description: "The primary language of the resource"
  field :identifiers,
        [IdentifierType],
        null: true,
        description:
          "An identifier or identifiers applied to the resource being registered"
  field :related_identifiers,
        [RelatedIdentifierType],
        null: true,
        description:
          "Identifiers of related resources. These must be globally unique identifiers"
  field :related_items,
        [RelatedItemType],
        null: true,
        description:
          "Information about a resource related to the one being registered e.g. a journal or book of which the article or chapter is part."
  field :types, ResourceTypeType, null: false, description: "The resource type"
  field :formats,
        [String],
        null: true, description: "Technical format of the resource"
  field :sizes,
        [String],
        null: true,
        description:
          "Size (e.g. bytes, pages, inches, etc.) or duration (extent), e.g. hours, minutes, days, etc., of a resource"
  field :version,
        String,
        null: true,
        hash_key: "version_info",
        description: "The version number of the resource"
  field :rights,
        [RightsType],
        null: true, description: "Any rights information for this resource"
  field :descriptions,
        [DescriptionType],
        null: true,
        description:
          "All additional information that does not fit in any of the other categories" do
    argument :first, Int, required: false, default_value: 5
  end
  field :container,
        ContainerType,
        null: true,
        description:
          "The container (e.g. journal or repository) hosting the resource."
  field :geolocations,
        [GeolocationType],
        null: true,
        hash_key: "geo_locations",
        description:
          "Spatial region or named place where the data was gathered or about which the data is focused."
  field :funding_references,
        [FundingType],
        null: true,
        description:
          "Information about financial support (funding) for the resource being registered"
  field :url,
        Url,
        null: true, description: "The URL registered for the resource"
  field :content_url,
        resolver: ContentUrl,
        null: true,
        description: "Url to download the content directly, if available"
  field :repository,
        RepositoryType,
        null: true,
        description: "The repository account managing this resource"
  field :member,
        MemberType,
        null: true,
        hash_key: "provider",
        description: "The member account managing this resource"
  field :registration_agency,
        RegistrationAgencyType,
        hash_key: "agency",
        null: true,
        description: "The DOI registration agency for the resource"
  field :formatted_citation,
        String,
        null: true, description: "Metadata as formatted citation" do
    argument :style, String, required: false, default_value: "apa"
    argument :locale, String, required: false, default_value: "en-US"
    argument :format, CitationFormat, required: false, default_value: "html"
  end
  field :xml,
        String,
        null: false, description: "Metadata in DataCite XML format."
  field :bibtex, String, null: false, description: "Metadata in bibtex format"
  field :schema_org,
        GraphQL::Types::JSON,
        null: false, description: "Metadata in schema.org format"
  field :claims,
        resolver: Claims,
        null: true,
        description: "Claims to ORCID made for this DOI."
  field :reference_count,
        Int,
        null: true, description: "Total number of references"
  field :citation_count,
        Int,
        null: true, description: "Total number of citations"
  field :view_count, Int, null: true, description: "Total number of views"
  field :download_count,
        Int,
        null: true, description: "Total number of downloads"
  field :version_count, Int, null: true, description: "Total number of versions"
  field :version_of_count,
        Int,
        null: true,
        description: "Total number of DOIs the resource is a version of"
  field :part_count, Int, null: true, description: "Total number of parts"
  field :part_of_count,
        Int,
        null: true,
        description: "Total number of DOIs the resource is a part of"
  field :other_related_count,
        Int,
        null: true,
        description: "Total number of DOIs related to the resource"
  field :citations_over_time,
        [YearTotalType],
        null: true, description: "Citations by year"
  field :views_over_time,
        [YearMonthTotalType],
        null: true, description: "Views by month"
  field :downloads_over_time,
        [YearMonthTotalType],
        null: true, description: "Downloads by month"

  field :references,
        WorkConnectionWithTotalType,
        null: true,
        max_page_size: 100,
        description: "References for this DOI" do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :citations,
        WorkConnectionWithTotalType,
        null: true,
        max_page_size: 100,
        description: "Citations for this DOI." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :other_related,
       WorkConnectionWithTotalType,
       null: true,
       max_page_size: 100,
       description: "Other works related to this DOI." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def other_related(**args)
    args[:ids] = get_other_related_ids(object.doi)
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def other_related_count
    get_other_related_ids(object.doi).count
  end

  def get_other_related_ids(_doi)
    Event.events_involving(_doi).map do |e|
      e.doi
    end.flatten.uniq - [_doi.downcase, nil]
  end


  field :parts,
        WorkConnectionWithTotalType,
        null: true, max_page_size: 100, description: "Parts of this DOI." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :part_of,
        WorkConnectionWithTotalType,
        null: true,
        max_page_size: 100,
        description: "The DOI is a part of this DOI." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :versions,
        WorkConnectionWithTotalType,
        null: true, max_page_size: 100, description: "Versions of this DOI." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  field :version_of,
        WorkConnectionWithTotalType,
        null: true,
        max_page_size: 100,
        description: "The DOI is a version of this DOI." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :published, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :organization_id, String, required: false
    argument :registration_agency, String, required: false
    argument :resource_type_id, String, required: false
    argument :license, String, required: false
    argument :language, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_affiliation, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :field_of_science, String, required: false
    argument :first, Int, required: false, default_value: 25
    argument :after, String, required: false
  end

  def type
    object.types["resourceTypeGeneral"] || "Work"
  end

  def repository
    if object.client.blank?
      return nil
    end
    ReferenceRepository.find_by_id(object.client.uid).first
  end

  def rights
    Array.wrap(object.rights_list)
  end

  def language
    return {} if object.language.blank?

    la = ISO_639.find_by_code(object.language)

    {
      id: object.language,
      name: la.present? ? la.english_name.split(/\W+/).first : object.language,
    }.compact
  end

  def registration_agency
    return {} if object.agency.blank?

    { id: object.agency, name: REGISTRATION_AGENCIES[object.agency] }.compact
  end

  def _fos_to_facet(fos_list)
    Array.wrap(fos_list).map do |name|
      { "id" => name.parameterize(separator: "_"), "name" => name }
    end.uniq
  end

  def fields_of_science_repository
    if object.client.blank?
      return []
    end
    _fos_to_facet(object.fields_of_science_repository)
  end

  def fields_of_science_combined
    _fos_to_facet(object.fields_of_science_combined)
  end

  def _fos_temp
    Array.wrap(object.subjects).select do |s|
      s["subjectScheme"] == "Fields of Science and Technology (FOS)"
    end.map do |s|
      s["subject"].gsub("FOS: ", "")
    end.uniq
  end
  def fields_of_science
    _fos_to_facet(_fos_temp)
  end

  def creators(**args)
    Array.wrap(object.creators)[0...args[:first]].map do |c|
      Hashie::Mash.new(
        "id" =>
          Array.wrap(c.fetch("nameIdentifiers", [])).detect do |n|
            %w[ORCID ROR].include?(n.fetch("nameIdentifierScheme", nil))
          end.to_h.
            fetch("nameIdentifier", nil),
        "name_type" => c.fetch("nameType", nil),
        "name" => c.fetch("name", nil),
        "given_name" => c.fetch("givenName", nil),
        "family_name" => c.fetch("familyName", nil),
        "affiliation" =>
          Array.wrap(c.fetch("affiliation", [])).map do |a|
            { "id" => a["affiliationIdentifier"], "name" => a["name"] }.compact
          end.compact,
      )
    end
  end

  def contributors(**args)
    contrib = Array.wrap(object.contributors)[0...args[:first]]
    if args[:contributor_type].present?
      contrib =
        contrib.select { |c| c["contributorType"] == args[:contributor_type] }
    end
    contrib.map do |c|
      Hashie::Mash.new(
        "id" =>
          Array.wrap(c.fetch("nameIdentifiers", [])).detect do |n|
            %w[ORCID ROR].include?(n.fetch("nameIdentifierScheme", nil))
          end.to_h.
            fetch("nameIdentifier", nil),
        "contributor_type" => c.fetch("contributorType", nil),
        "name_type" => c.fetch("nameType", nil),
        "name" => c.fetch("name", nil),
        "given_name" => c.fetch("givenName", nil),
        "family_name" => c.fetch("familyName", nil),
        "affiliation" =>
          Array.wrap(c.fetch("affiliation", [])).map do |a|
            { "id" => a["affiliationIdentifier"], "name" => a["name"] }.compact
          end.compact,
      )
    end
  end

  def titles(first: nil)
    Array.wrap(object.titles)[0...first]
  end

  def descriptions(first: nil)
    Array.wrap(object.descriptions)[0...first]
  end

  def identifiers
    Array.wrap(object.identifiers).select do |r|
      [doi_from_url(object.doi), object.url].compact.exclude?(r["identifier"])
    end
  end

  def publisher
    object.try(:publisher_obj) || object.try(:publisher)
  end

  def bibtex
    pages =
      if object.container.to_h["firstPage"].present?
        [object.container["firstPage"], object.container["lastPage"]].compact.
          join("-")
      end

    bib = {
      bibtex_type: object.types["bibtex"].presence || "misc",
      bibtex_key: normalize_doi(object.doi),
      doi: object.doi,
      url: object.url,
      author: authors_as_string(object.creators),
      keywords:
        if object.subjects.present?
          Array.wrap(object.subjects).map do |k|
            parse_attributes(k, content: "subject", first: true)
          end.join(", ")
        end,
      language: object.language,
      title: parse_attributes(object.titles, content: "title", first: true),
      journal: object.container && object.container["title"],
      volume: object.container.to_h["volume"],
      issue: object.container.to_h["issue"],
      pages: pages,
      publisher: object.publisher,
      year: object.publication_year,
    }.compact
    BibTeX::Entry.new(bib).to_s
  end

  def xml
    object.xml.force_encoding("UTF-8") if object.xml.present?
  end

  def schema_org
    hsh = {
      "@context" => "http://schema.org",
      "@type" => object.types.present? ? object.types["schemaOrg"] : nil,
      "@id" => normalize_doi(object.doi),
      "identifier" => to_schema_org_identifiers(object.identifiers),
      "url" => object.url,
      "additionalType" =>
        object.types.present? ? object.types["resourceType"] : nil,
      "name" => parse_attributes(object.titles, content: "title", first: true),
      "author" => to_schema_org_creators(object.creators),
      "editor" => to_schema_org_contributors(object.contributors),
      "description" =>
        parse_attributes(
          object.descriptions,
          content: "description", first: true,
        ),
      "license" =>
        Array.wrap(object.rights_list).map { |l| l["rightsUri"] }.compact.
          unwrap,
      "version" => object.version_info,
      "keywords" =>
        if object.subjects.present?
          Array.wrap(object.subjects).map do |k|
            parse_attributes(k, content: "subject", first: true)
          end.join(", ")
        end,
      "inLanguage" => object.language,
      "contentSize" => Array.wrap(object.sizes).unwrap,
      "encodingFormat" => Array.wrap(object.formats).unwrap,
      "dateCreated" => get_date(object.dates, "Created"),
      "datePublished" => get_date(object.dates, "Issued"),
      "dateModified" => get_date(object.dates, "Updated"),
      "pageStart" => object.container.to_h["firstPage"],
      "pageEnd" => object.container.to_h["lastPage"],
      "spatialCoverage" => to_schema_org_spatial_coverage(object.geo_locations),
      "sameAs" =>
        to_schema_org_relation(
          related_identifiers: object.related_identifiers,
          relation_type: "IsIdenticalTo",
        ),
      "isPartOf" =>
        to_schema_org_relation(
          related_identifiers: object.related_identifiers,
          relation_type: "IsPartOf",
        ),
      "hasPart" =>
        to_schema_org_relation(
          related_identifiers: object.related_identifiers,
          relation_type: "HasPart",
        ),
      "predecessor_of" =>
        to_schema_org_relation(
          related_identifiers: object.related_identifiers,
          relation_type: "IsPreviousVersionOf",
        ),
      "successor_of" =>
        to_schema_org_relation(
          related_identifiers: object.related_identifiers,
          relation_type: "IsNewVersionOf",
        ),
      "citation" =>
        to_schema_org_relation(
          related_identifiers: object.related_identifiers,
          relation_type: "References",
        ),
      "@reverse" => reverse.presence,
      "contentUrl" => Array.wrap(object.content_url).unwrap,
      "schemaVersion" => object.schema_version,
      "periodical" =>
        if object.types.present?
          (
            if (object.types["schemaOrg"] != "Dataset") &&
               object.container.present?
              to_schema_org(object.container)
            end
          )
        end,
      "includedInDataCatalog" =>
        if object.types.present?
          (
            if (object.types["schemaOrg"] == "Dataset") &&
               object.container.present?
              to_schema_org_container(object.container, type: "Dataset")
            end
          )
        end,
      "publisher" =>
        if object.publisher.present?
          { "@type" => "Organization", "name" => object.publisher }
        end,
      "funder" => to_schema_org_funder(object.funding_references),
      "provider" =>
        if object.agency.present?
          { "@type" => "Organization", "name" => object.agency }
        end,
    }.compact

    JSON.pretty_generate hsh
  end

  def reverse
    {
      "citation" =>
        Array.wrap(object.related_identifiers).select do |ri|
          ri["relationType"] == "IsReferencedBy"
        end.map do |r|
          {
            "@id" => normalize_doi(r["relatedIdentifier"]),
            "@type" => r["resourceTypeGeneral"] || "ScholarlyArticle",
            "identifier" =>
              r["relatedIdentifierType"] == "DOI" ? nil : to_identifier(r),
          }.compact
        end.unwrap,
      "isBasedOn" =>
        Array.wrap(object.related_identifiers).select do |ri|
          ri["relationType"] == "IsSupplementTo"
        end.map do |r|
          {
            "@id" => normalize_doi(r["relatedIdentifier"]),
            "@type" => r["resourceTypeGeneral"] || "ScholarlyArticle",
            "identifier" =>
              r["relatedIdentifierType"] == "DOI" ? nil : to_identifier(r),
          }.compact
        end.unwrap,
    }.compact
  end

  def build_bibliography(style: nil, locale: nil, format: nil)
    cp = CiteProc::Processor.new(
      style:  style  || "apa",
      locale: locale || "en-US",
      format: format || "html",
    )
    cp.import Array.wrap(citeproc_hsh)
    bibliographies = cp.render(:bibliography, id: normalize_doi(object.doi))
    bibliographies.first
  end

  def build_linked_bibliography(bibliography)
    _doi = object.doi
    url = _doi
    unless %r{^https?://}i.match?(_doi)
      url = "https://doi.org/#{_doi}"
    end
    bibliography.gsub(url, doi_link(url))
  end

  def formatted_citation(style: nil, locale: nil, format: nil)
    bibliography = build_bibliography(style: style, locale: locale, format: format)
    if format == "html"
      build_linked_bibliography(bibliography)
    else
      bibliography
    end
  end

  def references(**args)
    args[:ids] = object.reference_ids
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def citations(**args)
    args[:ids] = object.citation_ids
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def parts(**args)
    args[:ids] = object.part_ids
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def part_of(**args)
    args[:ids] = object.part_of_ids
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def versions(**args)
    args[:ids] = object.version_ids
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def version_of(**args)
    args[:ids] = object.version_of_ids
    ElasticsearchModelResponseConnection.new(
      response(args),
      context: context, first: args[:first], after: args[:after],
    )
  end

  def response(**args)
    # make sure no dois are returnded if there are no :ids
    args[:ids] = "999" if args[:ids].blank?

    Doi.gql_query(
      args[:query],
      ids: args[:ids],
      user_id: args[:user_id],
      client_id: args[:repository_id],
      provider_id: args[:member_id],
      resource_type_id: args[:resource_type_id],
      resource_type: args[:resource_type],
      published: args[:published],
      agency: args[:registration_agency],
      language: args[:language],
      license: args[:license],
      has_person: args[:has_person],
      has_funder: args[:has_funder],
      has_organization: args[:has_organization],
      has_affiliation: args[:has_affiliation],
      has_member: args[:has_member],
      has_citations: args[:has_citations],
      has_parts: args[:has_parts],
      has_versions: args[:has_versions],
      has_views: args[:has_views],
      has_downloads: args[:has_downloads],
      field_of_science: args[:field_of_science],
      pid_entity: args[:pid_entity],
      state: "findable",
      page: {
        cursor:
          args[:after].present? ? Base64.urlsafe_decode64(args[:after]) : [],
        size: args[:first],
      },
    )
  end

  def doi_link(url)
    "<a href='#{url}'>#{url}</a>"
  end

  def citeproc_hsh
    page =
      if object.container.to_h["firstPage"].present?
        [object.container["firstPage"], object.container["lastPage"]].compact.
          join("-")
      end
    if Array.wrap(object.creators).size == 1 &&
        Array.wrap(object.creators).first.fetch("name", nil) == ":(unav)"
      author = nil
    else
      author = to_citeproc(object.creators)
    end

    citeproc_type = if object.types["resourceTypeGeneral"] == "Software" &&
        object.version_info.present?
      "book"
    else
      object.types["citeproc"]
    end

    {
      "type" => citeproc_type,
      "id" => normalize_doi(object.doi),
      "categories" =>
        Array.wrap(object.subjects).map do |k|
          parse_attributes(k, content: "subject", first: true)
        end.presence,
      "language" => object.language,
      "author" => author,
      "contributor" => to_citeproc(object.contributors),
      "issued" =>
        if get_date(object.dates, "Issued")
          get_date_parts(get_date(object.dates, "Issued"))
        end,
      "submitted" =>
        Array.wrap(object.dates).detect do |d|
          d["dateType"] == "Submitted"
        end.to_h.
          fetch("__content__", nil),
      "abstract" =>
        parse_attributes(
          object.descriptions,
          content: "description", first: true,
        ),
      "container-title" => object.container.to_h["title"],
      "DOI" => object.doi,
      "volume" => object.container.to_h["volume"],
      "issue" => object.container.to_h["issue"],
      "page" => page,
      "publisher" => (object.publisher.is_a?(Hash) ? object.publisher&.fetch("name", nil) : object.publisher),
      "title" => parse_attributes(object.titles, content: "title", first: true),
      "URL" => object.url,
      "version" => object.version_info,
    }.compact.
      symbolize_keys
  end
end
