require 'maremma'

class Dataset < ActiveRecord::Base


  include Identifiable
  include Metadatable
  include Cacheable

  alias_attribute :uid, :doi
  attribute :client_id
  attribute :client_name
  attr_accessor :provider

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


  before_validation :set_defaults
  after_create  :update_doi_quota
  validate :doi_quota_exceeded
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


  def minted
    self.created_at
  end

  def update_doi_quota
    client = Client.find(self.datacentre)
    fail("Something went wrong when decreasing your DOI quota") unless client

    Client.update(client[:id], :doi_quota_used => client[:doi_quota_used] + 1, :doi_quota_allowed => client[:doi_quota_allowed] - 1 )

    provider = Provider.find(self.provider)
    fail("Something went wrong when decreasing your DOI quota") unless provider

    Provider.update(provider[:id],
      :doi_quota_used => provider[:doi_quota_used] + 1,
      :doi_quota_allowed => provider[:doi_quota_allowed] - 1
    )
  end

  def doi_quota_exceeded
    Client.find(self.datacentre).doi_quota_exceeded
    Provider.find(self.provider).doi_quota_exceeded
  end


  private

  def set_defaults
   set_datacentre unless datacentre
  end

  def set_datacentre
    r = Client.find_by(symbol: client_id)
    fail("client_id Not found") unless r.present?
    write_attribute(:datacentre, r.id)
    write_attribute(:provider, r.allocator)
  end

end
