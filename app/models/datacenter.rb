class Datacenter < ApplicationRecord
  # define table and attribute names
  # we rename name -> title, so that we can do symbol -> name
  # name is used as unique identifier for most of our records,
  # mapped to id in serializer
  self.table_name = "datacentre"
  alias_attribute :title, :name
  alias_attribute :name, :symbol
  alias_attribute :member_id, :allocator
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :name, :title, :member_id, :contact_email, :contact_name, :doi_quota_allowed, :doi_quota_used
  validates_uniqueness_of :name, message: "This name has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_numericality_of :doi_quota_allowed, :doi_quota_used
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :role_name, :in => %w( ROLE_DATACENTRE ), :message => "Role %s is not included in the list"

  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre
  belongs_to :member, class_name: 'Member', foreign_key: :allocator
  has_many :datasets

  after_create  :add_test_prefix

  def self.get_all(options={})

    collection = Datacenter
    collection = collection.query(options[:query]) if options[:query]

    # options[:allocator] = Member.find_by(symbol: options[:allocator]).id if options[:allocator].present?
    #
    # if options[:allocator].present?
    #   collection = collection.where(allocator: options[:allocator])
    #   @allocator = collection.where(allocator: options[:allocator]).group(:allocator).count.first
    # end

    if options[:allocator].present?
      member_id = Member.find_by(symbol: options[:allocator]).id
      allocators = [{ id: member_id,
                 member: options[:allocator],
                 count: Datacenter.where(allocator: member_id).count }]
    else
      allocators = Datacenter.where.not(allocator: nil).order("allocator DESC").group(:allocator).count
      allocators = allocators.map { |k,v| { id: k.to_s, member: k.to_s, count: v } }
    end
    #
    page = options[:page] || { number: 1, size: 1000 }
    #
    @datacenters = Datacenter.order(:allocator).page(page[:number]).per_page(page[:size])
    #
    meta = { total: @datacenters.total_entries,
             total_pages: @datacenters.total_pages ,
             page: page[:number].to_i,
            #  member_types: member_types,
            #  regions: regions,
             members: allocators }
    @datacenters
  end

  def add_test_prefix

  end
end
