# frozen_string_literal: true

module DoiItem
  include BaseInterface
  include Bolognese::MetadataUtils

  description "Information about DOIs"

  field :id, ID, null: false, hash_key: "identifier", description: "The persistent identifier for the resource"
  field :type, String, null: false, description: "The type of the item."
  field :creators, [PersonType], null: true, description: "The main researchers involved in producing the data, or the authors of the publication, in priority order" do
    argument :first, Int, required: false, default_value: 20
  end
  field :titles, [TitleType], null: true, description: "A name or title by which a resource is known" do
    argument :first, Int, required: false, default_value: 5
  end
  field :publication_year, Int, null: true, description: "The year when the data was or will be made publicly available"
  field :publisher, String, null: true, description: "The name of the entity that holds, archives, publishes prints, distributes, releases, issues, or produces the resource"
  field :subjects, [SubjectType], null: true, description: "Subject, keyword, classification code, or key phrase describing the resource"
  field :resource_type_general, String, null: true, hash_key: "resource_type_id", description: "The general type of a resource"
  field :dates, [DateType], null: true, description: "Different dates relevant to the work"
  field :language, String, null: true, description: "The primary language of the resource"
  field :identifiers, [IdentifierType], null: true, description: "An identifier or identifiers applied to the resource being registered"
  field :related_identifiers, [RelatedIdentifierType], null: true, description: "Identifiers of related resources. These must be globally unique identifiers"
  field :types, ResourceTypeType, null: true, description: "The resource type"
  field :formats, [String], null: true, description: "Technical format of the resource"
  field :sizes, [String], null: true, description: "Size (e.g. bytes, pages, inches, etc.) or duration (extent), e.g. hours, minutes, days, etc., of a resource"
  field :version, String, null: true, hash_key: "version_info", description: "The version number of the resource"
  field :rights, [RightsType], null: true, hash_key: "rights_list", description: "Any rights information for this resource"
  field :descriptions, [DescriptionType], null: true, description: "All additional information that does not fit in any of the other categories" do
    argument :first, Int, required: false, default_value: 5
  end
  field :funding_references, [FundingType], null: true, description: "Information about financial support (funding) for the resource being registered"
  field :url, String, null: true, description: "The URL registered for the resource"
  field :client, ClientType, null: true, description: "The client account managing this resource"
  field :provider, ProviderType, null: true, description: "The provider account managing this resource"
  field :formatted_citation, String, null: true, description: "Metadata as formatted citation" do
    argument :style, String, required: false, default_value: "apa"
    argument :locale, String, required: false, default_value: "en-US"
  end
  
  def type
    object.types["schemaOrg"]
  end

  def creators(first: nil)
    Array.wrap(object.creators[0...first]).map do |c|
      Hashie::Mash.new(
        "id" => c.fetch("nameIdentifiers", []).find { |n| n.fetch("nameIdentifierScheme", nil) == "ORCID" }.to_h.fetch("nameIdentifier", nil),
        "name_type" => c.fetch("nameType", nil),
        "name" => c.fetch("name", nil),
        "given_name" => c.fetch("givenName", nil),
        "family_name" => c.fetch("familyName", nil),
        "affiliation" => c.fetch("affiliation", []))
    end
  end

  def titles(first: nil)
    object.titles[0...first]
  end

  def descriptions(first: nil)
    object.descriptions[0...first]
  end

  # defaults to style: apa and locale: en-US
  def formatted_citation(style: nil, locale: nil)
    cp = CiteProc::Processor.new(style: style || "apa", locale: locale || "en-US", format: "html")
    cp.import Array.wrap(citeproc_hsh)
    bibliography = cp.render :bibliography, id: normalize_doi(object.doi)
    url = object.doi 
    unless /^https?:\/\//i.match?(object.doi)
      url = "https://doi.org/#{object.doi}"
    end
    bibliography.first.gsub(url, doi_link(url))
  end

  def doi_link(url)
    "<a href='#{url}'>#{url}</a>"
  end

  def citeproc_hsh
    page = object.container.to_h["firstPage"].present? ? [object.container["firstPage"], object.container["lastPage"]].compact.join("-") : nil
    if Array.wrap(object.creators).size == 1 && Array.wrap(object.creators).first.fetch("name", nil) == ":(unav)"
      author = nil
    else
      author = to_citeproc(object.creators)
    end

    {
      "type" => object.types["citeproc"],
      "id" => normalize_doi(object.doi),
      "categories" => Array.wrap(object.subjects).map { |k| parse_attributes(k, content: "subject", first: true) }.presence,
      "language" => object.language,
      "author" => author,
      "contributor" => to_citeproc(object.contributors),
      "issued" => get_date(object.dates, "Issued") ? get_date_parts(get_date(object.dates, "Issued")) : nil,
      "submitted" => Array.wrap(object.dates).find { |d| d["dateType"] == "Submitted" }.to_h.fetch("__content__", nil),
      "abstract" => parse_attributes(object.descriptions, content: "description", first: true),
      "container-title" => object.container.to_h["title"],
      "DOI" => object.doi,
      "volume" => object.container.to_h["volume"],
      "issue" => object.container.to_h["issue"],
      "page" => page,
      "publisher" => object.publisher,
      "title" => parse_attributes(object.titles, content: "title", first: true),
      "URL" => object.url,
      "version" => object.version_info
    }.compact.symbolize_keys
  end
end
