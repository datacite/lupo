class BillingInformationValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
        # Don't try to validate if we have nothing
        return unless value.present?
 
        unless value["city"].present? 
            record.errors[attribute] << "has no city specified"
        end

        unless value["state"].present? 
            record.errors[attribute] << "has no state/province specified"
        end
        unless value["country"].present? 
            record.errors[attribute] << "has no country specified"
        end
        unless value["department"].present? 
            record.errors[attribute] << "has no department specified"
        end

        unless value["address"].present? 
            record.errors[attribute] << "has no street address specified"
        end

        unless value["postCode"].present? || value["post_code"].present?
            record.errors[attribute] << "has no post/zip code specified"
        end
        unless value["organization"].present? 
            record.errors[attribute] << "has no organization specified"
        end
    end
end