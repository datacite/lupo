# frozen_string_literal: true

class DefinedTermType < BaseObject
  description "A word, name, acronym, phrase, etc. with a formal definition. Often used in the context of category or subject classification, glossaries or dictionaries, product or creative work types, etc."

  field :term_code, String, null: true, description: "A code that identifies this DefinedTerm within a DefinedTermSet."
  field :name, String, null: true, description: "The name of the item."
  field :description, String, null: true, description: "A description of the item."
  field :in_defined_term_set, String, null: true, description: "A DefinedTermSet that contains this term."
end
