class Prefix < ActiveRecord::Base


  self.table_name = "prefix"
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  alias_attribute :uid, :prefix

  validates_presence_of :prefix
  validates_uniqueness_of :prefix

  # validates_format_of :prefix, :with => /(10\.\d{4,5})\/.+\z/, :multiline => true
  validates_numericality_of :version, if: :version?

  has_and_belongs_to_many :datacenters, join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre, autosave: true
  has_and_belongs_to_many :members, join_table: "allocator_prefixes", foreign_key: :prefixes
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
    # # Elasticsearch indexing
    # mappings dynamic: 'false' do
    #   indexes :uid, type: 'text'
    #   indexes :prefix
    #   indexes :version, type: 'integer'
    #   indexes :created_at, type: 'date'
    # end

    def as_indexed_json(options={})
      {
        "id" => uid.downcase,
        "prefix" => prefix,
        "version" => version,
        "created" => created_at.iso8601,
        "updated" => updated_at.iso8601
       }
    end

    # Elasticsearch custom search
    def self.search(query, options={})
      # __elasticsearch__.search(
      #   {
      #     query: {
      #       query_string: {
      #         query: query,
      #         fields: ['uid^10', 'name^10', 'contact_email']
      #       }
      #     }
      #   }
      # )
      self.all
    end



    private

    def set_defaults

    end
end
