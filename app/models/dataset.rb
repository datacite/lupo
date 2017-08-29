require 'maremma'

class Dataset < ActiveRecord::Base


  include Identifiable
  include Metadatable
  include Cacheable

  alias_attribute :uid, :doi
  attribute :datacenter_id
  attribute :datacenter_name
  attribute :url
  # alias_attribute :datacenter_id, :datacentre
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  belongs_to :datacenter, class_name: 'Datacenter', foreign_key: :datacentre
  self.table_name = "dataset"

  validates_presence_of :doi, :datacentre
  validates_format_of :doi, :with => /(10\.\d{4,5})\/.+\z/
  validates_uniqueness_of :doi, message: "This DOI has already been taken"
  validates_numericality_of :version, if: :version?

  before_create :add_url
  before_create :is_quota_exceeded
  before_validation :set_datacentre
  after_create  :decrease_doi_quota
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  # # Elasticsearch indexing
  # mappings dynamic: 'false' do
  #   indexes :uid, type: 'text'
  #   indexes :doi, type: 'text'
  #   indexes :url, type: 'text'
  #   indexes :version, type: 'integer'
  #   indexes :is_active, type: 'binary'
  #   indexes :datacenter_id, type: 'text'
  #   indexes :minted, type: 'date'
  #   indexes :created_at, type: 'date'
  #   indexes :updated_at, type: 'date'
  # end

  def as_indexed_json(options={})
    {
      "id" => uid.downcase,
      "doi" => doi,
      "url" => url,
      "version" => version,
      "is_active" => is_active,
      "datacenter" => datacenter_id,
      "minted" => created_at.iso8601,
      "created" => created_at.iso8601,
      "updated" => updated_at.iso8601 }
  end

  # Elasticsearch custom search
  def self.search(query, options={})
    # __elasticsearch__.search(
    #   {
    #     query: {
    #       query_string: {
    #         query: query,
    #         fields: ['uid^10', 'name^10', 'description', 'contact_email', 'country_name', 'website']
    #       }
    #     }
    #   }
    # )
    #

    collection = cached_datasets_options(options)
    years = cached_years_response

    result = { response: collection,
               years: years.sort_by!{ |hsh| -hsh[:title] }
             }
  end


  def add_url
    self.url = Maremma.head(doi_as_url(self.doi)).url
  end

  def minted
    self.created_at
  end

  def datacenter_id
    @datacenter_id = Datacenter.find(datacentre).uid.downcase if datacentre
    @datacenter_id
  end

  def is_quota_exceeded
    datacenter = Datacenter.find(self.datacentre)
    fail("You have excceded your DOI quota. You cannot mint DOIs anymore.") if datacenter[:doi_quota_allowed] < 0
  end

  def decrease_doi_quota
    datacenter = Datacenter.find(self.datacentre)
    fail("Something went wrong when decreasing your DOI quota") unless Datacenter.update(datacenter[:id], doi_quota_allowed: datacenter[:doi_quota_allowed] - 1)
  end

  private

  def set_datacentre
    r = Datacenter.find_by(symbol: datacenter_id)
    fail("datacenter_id Not found") unless r.present?
    write_attribute(:datacentre, r.id)
  end

end
