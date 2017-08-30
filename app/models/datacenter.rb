class Datacenter < ActiveRecord::Base

  # include helper module for caching infrequently changing resources
  include Cacheable
  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  self.table_name = "datacentre"
  alias_attribute :uid, :symbol
  # alias_attribute :member_id, :allocator
  # attribute :member
  attribute :member_id
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :uid, :name, :member_id, :contact_email
  validates_uniqueness_of :uid, message: "This name has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_numericality_of :doi_quota_allowed, :doi_quota_used
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :role_name, :in => %w( ROLE_DATACENTRE ), :message => "Role %s is not included in the list"

  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre
  belongs_to :member, class_name: 'Member', foreign_key: :allocator
  has_many :datasets

  before_validation :set_defaults, :set_allocator

  delegate :uid, to: :member, prefix: true
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { where("symbol like ? OR name like ?", "%#{query}%", "%#{query}%") }

  # delegate :next_repetition,
  #          to: :meta_sm2
  #
  # alias_method :member_id, :next_repetition

  def year
    created_at.year if created_at.present?
  end


  def self.get_all(options={})
    collection = Datacenter
    if options[:id].present?
      collection = collection.where(symbol: options[:id])
    elsif options[:query].present?
      collection = collection.query(options[:query])
    end

    # cache members for faster queries
    if options["member-id"].present?
      member = cached_member_response(options["member-id"].upcase)
      collection = collection.where(allocator: member.id)
    end
    collection = collection.where('YEAR(created) = ?', options[:year]) if options[:year].present?

    # calculate facet counts after filtering
    if options["member-id"].present?
      members = [{ id: options["member-id"],
                   title: member.name,
                   count: collection.where(allocator: member.id).count }]
    else
      members = collection.where.not(allocator: nil).group(:allocator).count
      Rails.logger.info members.inspect
      members = members
                  .sort { |a, b| b[1] <=> a[1] }
                  .map do |i|
                         member = cached_members.find { |m| m.id == i[0] }
                         { id: member.symbol.downcase, title: member.name, count: i[1] }
                       end
    end
    if options[:year].present?
      years = [{ id: options[:year],
                 title: options[:year],
                 count: collection.where('YEAR(created) = ?', options[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(created) DESC").group("YEAR(created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end
    response ={
      collection: collection,
      years: years,
      members: members
    }
end

  # def domains
  #   domains.to_s.split(/\s*,\s*/).presence
  # end

  # def member_id
  #   @member_id = Member.find(allocator).uid.downcase if allocator
  #   @member_id
  # end

  private


  def set_defaults
    self.contact_name = "" unless contact_name.present?
    self.role_name = "ROLE_DATACENTRE" unless role_name.present?
    self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
    self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
  end

  def set_allocator
    r = Member.find_by(symbol: member_id)
    fail("member_id Not found") unless r.present?
    write_attribute(:allocator, r.id)
  end
end
