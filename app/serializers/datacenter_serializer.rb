class DatacenterSerializer < ActiveModel::Serializer
  attributes :id, :comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :allocator, :experiments
end
