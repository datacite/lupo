# frozen_string_literal: true

class ParamsSanitizer
  include Crosscitable
  include Helpable

  DEFAULTS_MAP =
    {
      data: {
        titles: [],
        descriptions: [],
        types: {},
        container: {},
        dates: [],
        subjects: [],
        rightsList: [],
        creators: [],
        contributors: [],
        sizes: [],
        formats: [],
        contentUrl: [],
        identifiers: [],
        relatedIdentifiers: [],
        relatedItems: [],
        fundingReferences: [],
        geoLocations: [],
      },
    }.freeze

  ATTRIBUTES_MAP =
  [
    :doi,
    :confirmDoi,
    :url,
    :titles,
    { titles: %i[title titleType lang] },
    :publisher,
      {
        publisher: %i[
          name
          publisherIdentifier
          publisherIdentifierScheme
          schemeUri
          lang
        ],
      },
    :publicationYear,
    :created,
    :prefix,
    :suffix,
    :types,
    {
      types: %i[
        resourceTypeGeneral
        resourceType
        schemaOrg
        bibtex
        citeproc
        ris
      ],
    },
    :dates,
    { dates: %i[date dateType dateInformation] },
    :subjects,
    { subjects: %i[subject subjectScheme schemeUri valueUri lang classificationCode] },
    :landingPage,
    {
      landingPage: [
        :checked,
        :url,
        :status,
        :contentType,
        :error,
        :redirectCount,
        { redirectUrls: [] },
        :downloadLatency,
        :hasSchemaOrg,
        :schemaOrgId,
        { schemaOrgId: [] },
        :dcIdentifier,
        :citationDoi,
        :bodyHasPid,
      ],
    },
    :contentUrl,
    { contentUrl: [] },
    :sizes,
    { sizes: [] },
    :formats,
    { formats: [] },
    :language,
    :descriptions,
    { descriptions: %i[description descriptionType lang] },
    :rightsList,
    {
      rightsList: %i[
        rights
        rightsUri
        rightsIdentifier
        rightsIdentifierScheme
        schemeUri
        lang
      ],
    },
    :xml,
    :regenerate,
    :source,
    :version,
    :metadataVersion,
    :schemaVersion,
    :state,
    :isActive,
    :reason,
    :registered,
    :updated,
    :mode,
    :event,
    :regenerate,
    :should_validate,
    :client,
    :creators,
    {
      creators: [
        :nameType,
        {
          nameIdentifiers: %i[nameIdentifier nameIdentifierScheme schemeUri],
        },
        :name,
        :givenName,
        :familyName,
        {
          affiliation: %i[
            name
            affiliationIdentifier
            affiliationIdentifierScheme
            schemeUri
          ],
        },
        :lang,
      ],
    },
    :contributors,
    {
      contributors: [
        :nameType,
        {
          nameIdentifiers: %i[nameIdentifier nameIdentifierScheme schemeUri],
        },
        :name,
        :givenName,
        :familyName,
        {
          affiliation: %i[
            name
            affiliationIdentifier
            affiliationIdentifierScheme
            schemeUri
          ],
        },
        :contributorType,
        :lang,
      ],
    },
    :identifiers,
    { identifiers: %i[identifier identifierType] },
    :alternateIdentifiers,
    { alternateIdentifiers: %i[alternateIdentifier alternateIdentifierType] },
    :relatedIdentifiers,
    {
      relatedIdentifiers: %i[
        relatedIdentifier
        relatedIdentifierType
        relationType
        relatedMetadataScheme
        schemeUri
        schemeType
        resourceTypeGeneral
        relatedMetadataScheme
        schemeUri
        schemeType
      ],
    },
    :fundingReferences,
    {
      fundingReferences: %i[
        funderName
        funderIdentifier
        funderIdentifierType
        awardNumber
        awardUri
        awardTitle
        schemeUri
      ],
    },
    :geoLocations,
    {
      geoLocations: [
        { geoLocationPoint: %i[pointLongitude pointLatitude] },
        {
          geoLocationBox: %i[
            westBoundLongitude
            eastBoundLongitude
            southBoundLatitude
            northBoundLatitude
          ],
        },
        {
          geoLocationPolygon: [
            { polygonPoint: %i[pointLongitude pointLatitude] },
            { inPolygonPoint: %i[pointLongitude pointLatitude]  },
          ],
        },
        :geoLocationPlace,
      ],
    },
    :container,
    {
      container: %i[
        type
        identifier
        identifierType
        title
        volume
        issue
        firstPage
        lastPage
      ],
    },
    :relatedItems,
    {
      relatedItems: [
        :relationType,
        :relatedItemType,
        {
          relatedItemIdentifier: %i[relatedItemIdentifier relatedItemIdentifierType relatedMetadataScheme schemeURI schemeType],
        },
        {
          creators: %i[nameType name givenName familyName],
        },
        {
          titles: %i[title titleType],
        },
        :publicationYear,
        :volume,
        :issue,
        :number,
        :numberType,
        :firstPage,
        :lastPage,
        :publisher,
        :edition,
        {
          contributors: %i[contributorType name givenName familyName nameType],
        },
      ],
    },
    :published,
    :downloadsOverTime,
    { downloadsOverTime: %i[yearMonth total] },
    :viewsOverTime,
    { viewsOverTime: %i[yearMonth total] },
    :citationsOverTime,
    { citationsOverTime: %i[year total] },
    :citationCount,
    :downloadCount,
    :partCount,
    :partOfCount,
    :referenceCount,
    :versionCount,
    :versionOfCount,
    :viewCount,
  ].freeze

  RELATIONSHIPS_MAP = [{ client: [data: %i[type id]] }].freeze

  def initialize(params = {})
    @params = params
  end

  def cleanse
    xml = add_xml

    meta = generate_meta(xml)
    add_schema_version(meta)
    xml = meta["string"]
    # if metadata for DOIs from other registration agencies are not found
    fail ActiveRecord::RecordNotFound if meta["state"] == "not_found"

    add_random_id

    # replace DOI, but otherwise don't touch the XML
    if meta["from"] == "datacite" && !params_have_metadata_attributes? && !@params[:schemaVersion].present?
      xml = replace_doi(xml, doi: @params[:doi] || meta["doi"])
    elsif xml.present? || params_have_metadata_attributes? || @params[:schemaVersion].present?
      regenerate = true
    end

    @params[:xml] = xml if xml.present?

    add_xml_attributes(meta)
    add_metadata_version(meta)
    add_landingpage()

    @params.merge(regenerate: @params[:regenerate] || regenerate).except(
      # ignore camelCase keys, and read-only keys
      :confirmDoi,
      :prefix,
      :suffix,
      :publicationYear,
      :alternateIdentifiers,
      :rightsList,
      :relatedIdentifiers,
      :relatedItems,
      :fundingReferences,
      :geoLocations,
      :metadataVersion,
      :schemaVersion,
      :state,
      :mode,
      :isActive,
      :landingPage,
      :created,
      :registered,
      :updated,
      :published,
      :lastLandingPage,
      :version,
      :lastLandingPageStatus,
      :lastLandingPageStatusCheck,
      :lastLandingPageStatusResult,
      :lastLandingPageContentType,
      :contentUrl,
      :viewsOverTime,
      :downloadsOverTime,
      :citationsOverTime,
      :citationCount,
      :downloadCount,
      :partCount,
      :partOfCount,
      :referenceCount,
      :versionCount,
      :versionOfCount,
      :viewCount,
    )
  end

  def params_have_metadata_attributes?
    [
      :creators,
      :contributors,
      :titles,
      :publisher,
      :publicationYear,
      :types,
      :descriptions,
      :container,
      :sizes,
      :formats,
      :version,
      :language,
      :dates,
      :identifiers,
      :alternateIdentifiers,
      :relatedIdentifiers,
      :relatedItems,
      :fundingReferences,
      :geoLocations,
      :rightsList,
      :subjects,
      :contentUrl,
    ].any? { |key| @params.has_key?(key) }
  end

  def get_params
    @params
  end

  def add_xml
    xml =
    @params[:xml].present? ? Base64.decode64(@params[:xml]).force_encoding("UTF-8") : nil

    if xml.present?
      # remove optional utf-8 bom
      xml.gsub!("\xEF\xBB\xBF", "")

      # remove leading and trailing whitespace
      xml.strip
    end
  end

  def add_xml_attributes(meta)
    read_attrs_keys = %i[
      url
      creators
      contributors
      titles
      publisher
      publicationYear
      types
      descriptions
      container
      sizes
      formats
      language
      dates
      identifiers
      relatedIdentifiers
      relatedItems
      fundingReferences
      geoLocations
      rightsList
      agency
      subjects
      contentUrl
      schemaVersion
    ]

    # merge attributes from xml into regular attributes
    # make sure we don't accidentally set any attributes to nil
    read_attrs_keys.each do |attr|
      if @params.has_key?(attr) || meta.has_key?(attr.to_s.underscore)
        @params.merge!(
          attr.to_s.underscore =>
            @params[attr] || meta[attr.to_s.underscore] || @params[attr],
        )
      end
    end
  end

  def add_landingpage
    # only update landing_page info if something is received via API to not overwrite existing data
    @params[:landing_page] = @params[:landingPage] if @params[:landingPage].present?
  end

  def add_metadata_version(hash)
    # handle version metadata
    if @params.has_key?(:version) || hash["version_info"].present?
      @params[:version_info] = @params[:version] || hash["version_info"]
    end
  end

  def add_random_id
    # generate random DOI if no DOI is provided
    # make random DOI predictable in test
    if @params[:doi].blank? && @params[:prefix].present? && Rails.env.test?
      @params[:doi] = generate_random_dois(@params[:prefix], number: 123_456).first
    elsif @params[:doi].blank? && @params[:prefix].present?
      @params[:doi] = generate_random_dois(@params[:prefix]).first
    end
  end

  def generate_meta(xml)
    xml.present? ? parse_xml(xml, doi: @params[:doi]) : {}
  end

  def add_schema_version(hash)
    @params[:schemaVersion] =
      if METADATA_FORMATS.include?(hash["from"])
        LAST_SCHEMA_VERSION
      else
        @params[:schemaVersion]
      end
  end

  def self.sanitize_nameIdentifiers(array)
    Array.wrap(array)&.each do |c|
      if c[:nameIdentifiers]&.respond_to?(:keys)
        fail(
          ActionController::UnpermittedParameters,
          ["nameIdentifiers must be an Array"],
        )
      end
    end
  end
end
