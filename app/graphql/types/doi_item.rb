# frozen_string_literal: true

module DoiItem
  include BaseInterface
  include Bolognese::MetadataUtils

  description "Information about DOIs"

  field :id, ID, null: false, hash_key: "identifier", description: "The persistent identifier for the resource"
  field :type, String, null: false, description: "The type of the item."
  field :creators, [CreatorType], null: true, description: "The main researchers involved in producing the data, or the authors of the publication, in priority order" do
    argument :first, Int, required: false, default_value: 20
  end
  field :titles, [TitleType], null: true, description: "A name or title by which a resource is known" do
    argument :first, Int, required: false, default_value: 5
  end
  field :publication_year, Int, null: true, description: "The year when the data was or will be made publicly available"
  field :publisher, String, null: true, description: "The name of the entity that holds, archives, publishes prints, distributes, releases, issues, or produces the resource"
  field :subjects, [SubjectType], null: true, description: "Subject, keyword, classification code, or key phrase describing the resource"
  field :dates, [DateType], null: true, description: "Different dates relevant to the work"
  field :language, String, null: true, description: "The primary language of the resource"
  field :identifiers, [IdentifierType], null: true, description: "An identifier or identifiers applied to the resource being registered"
  field :related_identifiers, [RelatedIdentifierType], null: true, description: "Identifiers of related resources. These must be globally unique identifiers"
  field :types, ResourceTypeType, null: false, description: "The resource type"
  field :formats, [String], null: true, description: "Technical format of the resource"
  field :sizes, [String], null: true, description: "Size (e.g. bytes, pages, inches, etc.) or duration (extent), e.g. hours, minutes, days, etc., of a resource"
  field :version, String, null: true, hash_key: "version_info", description: "The version number of the resource"
  field :rights, [RightsType], null: true, hash_key: "rights_list", description: "Any rights information for this resource"
  field :descriptions, [DescriptionType], null: true, description: "All additional information that does not fit in any of the other categories" do
    argument :first, Int, required: false, default_value: 5
  end
  field :funding_references, [FundingType], null: true, description: "Information about financial support (funding) for the resource being registered"
  field :url, Url, null: true, description: "The URL registered for the resource"
  field :repository, RepositoryType, null: true, description: "The repository account managing this resource"
  field :member, MemberType, null: true, description: "The member account managing this resource"
  field :registration_agency, String, hash_key: "agency", null: true, description: "The DOI registration agency for the resource"
  field :formatted_citation, String, null: true, description: "Metadata as formatted citation" do
    argument :style, String, required: false, default_value: "apa"
    argument :locale, String, required: false, default_value: "en-US"
  end
  field :bibtex, String, null: true, description: "Metadata in bibtex format"
  field :reference_count, Int, null: true, description: "Total number of references"
  field :citation_count, Int, null: true, description: "Total number of citations"
  field :view_count, Int, null: true, description: "Total number of views"
  field :download_count, Int, null: true, description: "Total number of downloads"
  field :version_count, Int, null: true, description: "Total number of versions"
  field :version_of_count, Int, null: true, description: "Total number of DOIs the resource is a version of"
  field :part_count, Int, null: true, description: "Total number of parts"
  field :part_of_count, Int, null: true, description: "Total number of DOIs the resource is a part of"
  field :citations_over_time, [YearTotalType], null: true, description: "Citations by year"
  field :views_over_time, [YearMonthTotalType], null: true, description: "Views by month"
  field :downloads_over_time, [YearMonthTotalType], null: true, description: "Downloads by month"
  
  field :references, WorkConnectionType, null: true, connection: true, max_page_size: 100, description: "References for this DOI" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end
  field :citations, WorkConnectionType, null: true, connection: true, max_page_size: 100, description: "Citations for this DOI." do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end
  field :parts, WorkConnectionType, null: true, connection: true, max_page_size: 100, description: "Parts of this DOI." do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end
  field :part_of, WorkConnectionType, null: true, connection: true, max_page_size: 100, description: "The DOI is a part of this DOI." do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end
  field :versions, WorkConnectionType, null: true, connection: true, max_page_size: 100, description: "Versions of this DOI." do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :affiliation_id, String, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end
  field :version_of, WorkConnectionType, null: true, connection: true, max_page_size: 100, description: "The DOI is a version of this DOI." do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :repository_id, String, required: false
    argument :member_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def type
    object.types["resourceTypeGeneral"]
  end

  def creators(**args)
    Array.wrap(object.creators[0...args[:first]]).map do |c|
      Hashie::Mash.new(
        "id" => c.fetch("nameIdentifiers", []).find { |n| n.fetch("nameIdentifierScheme", nil) == "ORCID" }.to_h.fetch("nameIdentifier", nil),
        "name_type" => c.fetch("nameType", nil),
        "name" => c.fetch("name", nil),
        "given_name" => c.fetch("givenName", nil),
        "family_name" => c.fetch("familyName", nil),
        "affiliation" => c.fetch("affiliation", []).map do |a|
          { "id" => a["affiliationIdentifier"],
            "name" => a["name"] }.compact
        end)
    end
  end

  def titles(first: nil)
    object.titles[0...first]
  end

  def descriptions(first: nil)
    object.descriptions[0...first]
  end

  def bibtex
    pages = object.container.to_h["firstPage"].present? ? [object.container["firstPage"], object.container["lastPage"]].join("-") : nil

    bib = {
      bibtex_type: object.types["bibtex"].presence || "misc",
      bibtex_key: normalize_doi(object.doi),
      doi: object.doi,
      url: object.url,
      author: authors_as_string(object.creators),
      keywords: object.subjects.present? ? Array.wrap(object.subjects).map { |k| parse_attributes(k, content: "subject", first: true) }.join(", ") : nil,
      language: object.language,
      title: parse_attributes(object.titles, content: "title", first: true),
      journal: object.container && container["title"],
      volume: object.container.to_h["volume"],
      issue: object.container.to_h["issue"],
      pages: pages,
      publisher: object.publisher,
      year: object.publication_year
    }.compact
    BibTeX::Entry.new(bib).to_s
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

  def references(**args)
    ids = object.reference_ids
    return [] if ids.blank?

    response(**args)
  end
  
  def citations(**args)
    args[:ids] = object.citation_ids
    return [] if args[:ids].blank?

    response(**args)
  end

  def parts(**args)
    args[:ids] = object.part_ids
    return [] if args[:ids].blank?

    response(**args)
  end

  def part_of(**args)
    args[:ids] = object.part_of_ids
    return [] if args[:ids].blank?

    response(**args)
  end

  def versions(**args)
    args[:ids] = object.version_ids
    return [] if args[:ids].blank?

    response(**args)
  end

  def version_of(**args)
    args[:ids] = object.version_of_ids
    return [] if args[:ids].blank?

    response(**args)
  end

  def response(**args)
    return [] if args[:ids].blank?

    Doi.query(args[:query], ids: args[:ids], funder_id: args[:funder_id], user_id: args[:user_id], repository_id: args[:repository_id], member_id: args[:member_id], affiliation_id: args[:affiliation_id], has_person: args[:has_person], has_funder: args[:has_funder], has_organization: args[:has_organization], has_citations: args[:has_citations], has_parts: args[:has_parts], has_versions: args[:has_versions], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] }).results.to_a
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
