require "countries"

class Member < ActiveRecord::Base


  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  self.table_name = "allocator"
  attribute :member_type
  alias_attribute :uid, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :uid, :name, :contact_email, :country_code
  validates_uniqueness_of :uid, message: "This name has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, message: "contact_email should be an email"
  validates_format_of :website, :with => /https?:\/\/[\S]+/ , if: :website?, message: "Website should be an url"
  validates_numericality_of :doi_quota_allowed, :doi_quota_used
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :role_name, :in => %w( ROLE_ALLOCATOR ROLE_ADMIN ROLE_DEV ), :message => "Role %s is not included in the list", if: :role_name?

  has_many :datacenters
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator

  before_validation :set_region, :set_defaults, :set_member_type
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
  accepts_nested_attributes_for :prefixes
  # # Elasticsearch indexing
  # mappings dynamic: 'false' do
  #   indexes :uid, type: 'text'
  #   indexes :name, type: 'text'
  #   indexes :description, type: 'text'
  #   indexes :contact_email, type: 'text'
  #   indexes :country_code, type: 'text'
  #   indexes :country_name, type: 'text'
  #   indexes :region, type: 'text'
  #   indexes :region_name, type: 'text'
  #   indexes :member_type, type: 'text'
  #   indexes :year, type: 'integer'
  #   indexes :website, type: 'text'
  #   indexes :phone, type: 'text'
  #   indexes :image_url, type: 'text'
  #   indexes :created_at, type: 'date'
  #   indexes :updated_at, type: 'date'
  # end

  def as_indexed_json(options={})
    {
      "id" => uid.downcase,
      "name" => name,
      "description" => description,
      "member_type" => member_type,
      "region" => region_name,
      "country" => country_name,
      "year" => year,
      "logo_url" => logo_url,
      "email" => contact_email,
      "website" => website,
      "phone" => phone,
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
    collection = self.where(options).all

    collection.each do |line|
      if line[:doi_quota_allowed] != 0
        r = "allocating"
      else
        r = "non_allocating"
      end
      line[:member_type] = r
    end

    years = nil
    years = collection.map{|member| { id: member[:id],  year: member[:created].year }}.group_by { |d| d[:year] }.map{ |k, v| { id: k, title: k, count: v.count} }
    member_types = nil
    member_types = collection.map{|member| { id: member[:id],  member_type: member[:member_type] }}.group_by { |d| d[:member_type] }.map{ |k, v| { id: k, title: k, count: v.count} }
    regions = nil
    regions = collection.map{|member| { id: member[:id],  region: member[:region] }}.group_by { |d| d[:region] }.map{ |k, v| { id: k, title: k, count: v.count} }

    result = { response: collection,
               member_types: member_types,
               years: years
            }
  end

  def year
    created.year
  end

  def member_type
    if doi_quota_allowed != 0
      r = "allocating"
    else
      r = "non_allocating"
    end
    r
  end


  def country_name
    return nil unless country_code.present?

    ISO3166::Country[country_code].name
  end

  def regions
    { "AMER" => "Americas",
      "APAC" => "Asia Pacific",
      "EMEA" => "EMEA" }
  end

  def region_name
    regions[region]
  end

  def logo_url
    "#{ENV['CDN_URL']}/images/members/#{uid.downcase}.png"
  end

  private

  def set_region
    if country_code.present?
      r = ISO3166::Country[country_code].world_region
    else
      r = nil
    end
    write_attribute(:region, r)
  end

  def set_member_type
    if doi_quota_allowed != 0
      r = "allocating"
    else
      r = "non_allocating"
    end
    r
  end

  def set_defaults
    self.contact_name = "" unless contact_name.present?
    self.role_name = "ROLE_ALLOCATOR" unless role_name.present?
    self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
    self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
  end
end
