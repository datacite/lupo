# frozen_string_literal: true

module DoiItem
  include BaseInterface

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
  field :formatted_citation, String, null: true, description: "Metadata as formatted citation"
  
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

  def formatted_citation(style: "apa", locale: "en-US")
    object.style = style
    object.locale = locale
    object.citation
  end
end
