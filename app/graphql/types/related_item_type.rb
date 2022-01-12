# frozen_string_literal: true

class RelatedItemType < BaseObject
  description "Information about related items"

  field :related_item_type,
        String,
        null: false,
        hash_key: "relatedItemType",
        description: "Related item type"
  field :relation_type,
        String,
        null: false,
        hash_key: "relationType",
        description: "Relation type"
  field :related_item_identifier,
        RelatedItemIdentifierType,
        null: true,
        hash_key: "relatedItemIdentifier",
        description: "Related item identifier"
  field :creators,
        [RelatedItemCreatorType],
        null: true,
        description: "The institutions or persons responsible for creating the related resource"
  field :contributors,
        [RelatedItemContributorType],
        null: true,
        description:
          "The institutions or persons responsible for collecting, managing, distributing, or otherwise contributing to the development of the resource."
  field :titles,
        [TitleType],
        null: false,
        description: "Titles of the related item"
  field :volume,
        String,
        null: true,
        description: "Volume of the related item"
  field :issue,
        String,
        null: true,
        description: "Issue number or name of the related item"
  field :number,
        String,
        null: true,
        description: "Number of the related item, e.g., report number of article number"
  field :number_type,
        String,
        null: true,
        hash_key: "numberType",
        description: "Type of the related item's number"
  field :first_page,
        String,
        null: true,
        hash_key: "firstPage",
        description: "First page of the related item"
  field :last_page,
        String,
        null: true,
        hash_key: "lastPage",
        description: "Last page of the related item"
  field :publisher,
        String,
        null: true,
        description: "Publisher of the related item"
  field :publication_year,
        String,
        null: true,
        hash_key: "publicationYear",
        description: "Publication year of the related item"
  field :edition,
        String,
        null: true,
        description: "Edition or version of the related item"
end
