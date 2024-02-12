# frozen_string_literal: true

class MemberSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :dash
  set_type :members
  set_id :uid
  # don't cache members, as they use the provider model

  attributes :title,
             :display_title,
             :description,
             :member_type,
             :organization_type,
             :focus_area,
             :region,
             :country,
             :year,
             :logo_url,
             :email,
             :website,
             :joined,
             :created,
             :updated

  attribute :title, &:name

  attribute :display_title, &:display_name

  attribute :email,
            if:
              Proc.new { |object, params|
                params[:current_ability] &&
                  params[:current_ability].can?(
                    :read_contact_information,
                    object,
                  ) ==
                    true
              } do |object|
    object.group_email
  end

  attribute :country, &:country_code
end
