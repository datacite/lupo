class MetadataSanitizer
  include Crosscitable
  include Helpable

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

    read_attrs = [
      @params[:creators],
      @params[:contributors],
      @params[:titles],
      @params[:publisher],
      @params[:publicationYear],
      @params[:types],
      @params[:descriptions],
      @params[:container],
      @params[:sizes],
      @params[:formats],
      @params[:version],
      @params[:language],
      @params[:dates],
      @params[:identifiers],
      @params[:relatedIdentifiers],
      @params[:relatedItems],
      @params[:fundingReferences],
      @params[:geoLocations],
      @params[:rightsList],
      @params[:subjects],
      @params[:contentUrl],
      @params[:schemaVersion],
    ].compact

    add_random_id

    # replace DOI, but otherwise don't touch the XML
    # use Array.wrap(read_attrs.first) as read_attrs may also be [[]]
    if meta["from"] == "datacite" && Array.wrap(read_attrs.first).blank?
      xml = replace_doi(xml, doi: @params[:doi] || meta["doi"])
    elsif xml.present? || Array.wrap(read_attrs.first).present?
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

  def get_params
    @params
  end

  def add_xml
    # extract attributes from xml field and merge with attributes provided directly
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

  def self.sanitaize_nameIdentifiers(array)
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
