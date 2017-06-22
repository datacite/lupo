class AllocatorSerializer < ActiveModel::Serializer
  attributes :id, :comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :experiments
end
