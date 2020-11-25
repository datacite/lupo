# frozen_string_literal: true

class BillingInformationValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # Don't try to validate if we have nothing
    return if value.blank?

    record.errors[attribute] << "has no city specified" if value["city"].blank?

    if value["state"].blank?
      record.errors[attribute] << "has no state/province specified"
    end

    if value["country"].blank?
      record.errors[attribute] << "has no country specified"
    end

    if value["department"].blank?
      record.errors[attribute] << "has no department specified"
    end

    if value["address"].blank?
      record.errors[attribute] << "has no street address specified"
    end

    unless value["postCode"].present? || value["post_code"].present?
      record.errors[attribute] << "has no post/zip code specified"
    end

    if value["organization"].blank?
      record.errors[attribute] << "has no organization specified"
    end
  end
end
