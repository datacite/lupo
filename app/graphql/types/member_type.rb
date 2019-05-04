module Types
  class MemberType < Types::BaseObject
    description "Information about members"

    field :id, ID, null: false, hash_key: 'uid', description: "Unique identifier for each member and can't be changed."
    field :name, String, null: false, description: "Member name"
    field :ror_id, String, null: false, description: "Research Organization Registry (ROR) identifier"
    field :description, String, null: true, description: "Description of the member"
    field :website, String, null: true, description: "Website of the member"
    field :contact_name, String, null: true, description: "Member contact name"
    field :contact_email, String, null: true, description: "Member contact email"
    field :logoUrl, String, null: true, description: "URL for the member logo"
    field :region, String, null: true, description: "Geographic region where the member is located"
    field :country_code, String, null: true, description: "Country where the member is located"
    field :organization_type, String, null: true
    field :focus_area, String, null: true, description: "Field of science covered by member"
  end
end
