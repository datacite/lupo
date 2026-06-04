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
        description:
          "The name of the subject scheme or classification code or authority if one is used"

  def subject_scheme
    object["subjectScheme"]
  end

  field :scheme_uri,
        String,
        null: true,
        description: "The URI of the subject identifier scheme"

  def scheme_uri
    object["schemeUri"]
  end

  field :value_uri,
        String,
        null: true,
        description: "The URI of the subject term"

  def value_uri
    object["valueUri"]
  end

  field :classification_code,
        String,
        null: true,
        description: "The classification code used for the subject term in the subject scheme"

  def classification_code
    object["classificationCode"]
  end

  field :lang, ID, null: true, description: "Language"
end
