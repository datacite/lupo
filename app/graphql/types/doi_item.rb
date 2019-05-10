# frozen_string_literal: true

module DoiItem
  include BaseInterface

  description "Information about DOIs"

  field :id, ID, null: false, hash_key: "identifier", description: "The persistent identifier for the resource"
  field :creators, [ResearcherType], null: true, description: "The main researchers involved in producing the data, or the authors of the publication, in priority order"
  field :titles, [TitleType], null: true, description: "A name or title by which a resource is known"
  field :publication_year, Int, null: true, description: "The year when the data was or will be made publicly available"
  field :publisher, String, null: true, description: "The name of the entity that holds, archives, publishes prints, distributes, releases, issues, or produces the resource"
  field :subjects, [Types::SubjectType], null: true, description: "Subject, keyword, classification code, or key phrase describing the resource"
  field :resource_type_general, String, null: true, hash_key: "resource_type_id", description: "The general type of a resource"
  field :dates, [Types::DateType], null: true, description: "Different dates relevant to the work"
  field :language, String, null: true, description: "The primary language of the resource"
  field :identifiers, [Types::IdentifierType], null: true, description: "An identifier or identifiers applied to the resource being registered"
  field :related_identifiers, [Types::RelatedIdentifierType], null: true, description: "Identifiers of related resources. These must be globally unique identifiers"
  field :types, Types::ResourceTypeType, null: true, description: "The resource type"
  field :formats, [String], null: true, description: "Technical format of the resource"
  field :sizes, [String], null: true, description: "Size (e.g. bytes, pages, inches, etc.) or duration (extent), e.g. hours, minutes, days, etc., of a resource"
  field :version, String, null: true, hash_key: "version_info", description: "The version number of the resource"
  field :rights, [Types::RightsType], null: true, hash_key: "rights_list", description: "Any rights information for this resource"
  field :descriptions, [Types::DescriptionType], null: true, description: "All additional information that does not fit in any of the other categories"
  field :funding_references, [Types::FundingType], null: true, description: "Information about financial support (funding) for the resource being registered"
  field :url, String, null: true, description: "The URL registered for the resource"
  field :client, ClientType, null: true, description: "The client account managing this resource"
  field :provider, ProviderType, null: true, description: "The provider account managing this resource"
end
