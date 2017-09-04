require 'maremma'

class Dataset < ActiveRecord::Base


  include Identifiable
  include Metadatable
  include Cacheable

  alias_attribute :uid, :doi
  attribute :client_id
  attribute :client_name
  # attr_accessor :url
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  belongs_to :client, class_name: 'Client', foreign_key: :datacentre
  has_many :media, class_name: 'Media'
  has_many :metadata, class_name: 'Metadata'
  self.table_name = "dataset"

  validates_presence_of :uid, :doi, :client_id
  validates_format_of :doi, :with => /(10\.\d{4,5})\/.+\z/
  validates_format_of :url, :with => /https?:\/\/[\S]+/ , if: :url?, message: "Website should be an url"
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
    collection = collection.where(datacentre:  Client.find_by(symbol: options[:client_id]).id) if options[:client_id].present?
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

  # def client_id
  #   @client_id = Client.find(datacentre).uid.downcase if datacentre
  #   @client_id
  # end

  # def is_quota_exceeded
  #   client = Client.find(self.datacentre)
  #   fail("You have excceded your DOI quota. You cannot mint DOIs anymore.") if client[:doi_quota_allowed] < 0
  # end
  #
  # def decrease_doi_quota
  #   client = Client.find(self.datacentre)
  #   fail("Something went wrong when decreasing your DOI quota") unless Client.update(client[:id], doi_quota_allowed: client[:doi_quota_allowed] - 1)
  # end

  private

  def set_defaults
   set_datacentre unless datacentre
  end

  def set_datacentre
    r = Client.find_by(symbol: client_id)
    fail("client_id Not found") unless r.present?
    write_attribute(:datacentre, r.id)
  end

end
