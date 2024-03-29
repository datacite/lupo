# frozen_string_literal: true

class SubjectType < BaseObject
  description "Subject information"

  field :subject,
        String,
        null: true,
        description:
          "Subject, keyword, classification code, or key phrase describing the resource"
  field :subject_scheme,
        String,
        null: true,
        hash_key: "subjectScheme",
        description:
          "The name of the subject scheme or classification code or authority if one is used"
  field :scheme_uri,
        String,
        null: true,
        hash_key: "schemeUri",
        description: "The URI of the subject identifier scheme"
  field :value_uri,
        String,
        null: true,
        hash_key: "valueUri",
        description: "The URI of the subject term"
  field :classification_code,
        String,
        null: true,
        hash_key: "classificationCode",
        description: "The classification code used for the subject term in the subject scheme"
  field :lang, ID, null: true, description: "Language"
end
