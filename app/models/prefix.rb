class Prefix < ActiveRecord::Base
  # index in Elasticsearch
  include Indexable

  self.table_name = "prefix"
  alias_attribute :created_at, :created

  validates_presence_of :prefix
  validates_uniqueness_of :prefix

  # validates_format_of :prefix, :with => /(10\.\d{4,5})\/.+\z/, :multiline => true
  validates_numericality_of :version, if: :version?

  has_and_belongs_to_many :datacenters, join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre, autosave: true
  has_and_belongs_to_many :members, join_table: "allocator_prefixes", foreign_key: :prefixes
end
