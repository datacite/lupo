class DatacentreResource < JSONAPI::Resource
  attributes  :comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :allocator, :experiments
  has_many :datasets
  has_many :prefixes
  has_one :allocator, class_name: 'Allocator', foreign_key: "allocator"
end
