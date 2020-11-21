class ContactValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # Don't try to validate if we have nothing
    return if value.blank?

    # Email validation
    unless value["email"].present? && value["email"] =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << "has an invalid email"
    end

    # Name validation
    if value["given_name"].blank?
      record.errors[attribute] << "has no givenName specified"
    end

    if value["family_name"].blank?
      record.errors[attribute] << "has no familyName specified"
    end
  end
end
