# frozen_string_literal: true

class RelatedItemType < BaseObject
  description "Information about related items"

  field :related_item_type,
        String,
        null: false,
        description: "Related item type"

  def related_item_type
    object["relatedItemType"]
  end

  field :relation_type,
        String,
        null: false,
        description: "Relation type"

  def relation_type
    object["relationType"]
  end

  field :related_item_identifier,
        RelatedItemIdentifierType,
        null: true,
        description: "Related item identifier"

  def related_item_identifier
    object["relatedItemIdentifier"]
  end

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
        description: "Type of the related item's number"

  def number_type
    object["numberType"]
  end

  field :first_page,
        String,
        null: true,
        description: "First page of the related item"

  def first_page
    object["firstPage"]
  end

  field :last_page,
        String,
        null: true,
        description: "Last page of the related item"

  def last_page
    object["lastPage"]
  end

  field :publisher,
        String,
        null: true,
        description: "Publisher of the related item"
  field :publication_year,
        String,
        null: true,
        description: "Publication year of the related item"

  def publication_year
    object["publicationYear"]
  end

  field :edition,
        String,
        null: true,
        description: "Edition or version of the related item"
end
