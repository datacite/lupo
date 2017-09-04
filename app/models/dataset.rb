require 'maremma'

class Dataset < ActiveRecord::Base


  include Identifiable
  include Metadatable
  include Cacheable

  alias_attribute :uid, :doi
  attribute :datacenter_id
  attribute :datacenter_name
  # attr_accessor :url
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  belongs_to :datacenter, class_name: 'Datacenter', foreign_key: :datacentre
  has_many :media, class_name: 'Media'
  has_many :metadata, class_name: 'Metadata'
  self.table_name = "dataset"

  validates_presence_of :uid, :doi, :datacenter_id
  validates_format_of :doi, :with => /(10\.\d{4,5})\/.+\z/
  validates_uniqueness_of :doi, message: "This DOI has already been taken"
  validates_numericality_of :version, if: :version?

  # before_create :add_url
  # before_create :is_quota_exceeded
  before_validation :set_defaults
  # after_create  :decrease_doi_quota
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { where("doi like ? OR title like ?", "%#{query}%", "%#{query}%") }


  # Elasticsearch custom search
  def self.get_all(query, options={})

    collection = self
    collection = collection.where('extract(year  from created) = ?', options[:year]) if options[:year].present?
    collection = collection.where(datacentre:  Datacenter.find_by(symbol: options[:datacenter_id]).id) if options[:datacenter_id].present?
    collection = collection.all unless options.values.include?([nil,nil])

    years = cached_years_response

    result = { response: collection,
               years: years.sort_by!{ |hsh| -hsh[:title] }
             }
  end


  # def url
  #   Maremma.head(doi_as_url(self.doi)).url
  # end

  def minted
    self.created_at
  end

  # def datacenter_id
  #   @datacenter_id = Datacenter.find(datacentre).uid.downcase if datacentre
  #   @datacenter_id
  # end

  # def is_quota_exceeded
  #   datacenter = Datacenter.find(self.datacentre)
  #   fail("You have excceded your DOI quota. You cannot mint DOIs anymore.") if datacenter[:doi_quota_allowed] < 0
  # end
  #
  # def decrease_doi_quota
  #   datacenter = Datacenter.find(self.datacentre)
  #   fail("Something went wrong when decreasing your DOI quota") unless Datacenter.update(datacenter[:id], doi_quota_allowed: datacenter[:doi_quota_allowed] - 1)
  # end

  private

  def set_defaults
   set_datacentre unless datacentre
  end

  def set_datacentre
    r = Datacenter.find_by(symbol: datacenter_id)
    fail("datacenter_id Not found") unless r.present?
    write_attribute(:datacentre, r.id)
  end

end
