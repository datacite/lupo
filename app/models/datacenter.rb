class Datacenter < ApplicationRecord
  self.table_name = "datacentre"
  # alias_attribute :created_at, :created
  # alias_attribute :updated_at, :updated
  attribute :member_id
  # alias_attribute :member_id, :allocator
  attribute :datacenter_id
  alias_attribute :datacenter_id, :symbol
  # attribute :title
  # alias_attribute :title, :symbol
  validates_presence_of :name, :member_id
  validates_presence_of :datacenter_id
  validates_uniqueness_of :datacenter_id, message: "This datacenter_id has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_numericality_of :doi_quota_allowed, :doi_quota_used
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :role_name, :in => %w( ROLE_DATACENTRE ), :message => "Role {{value}} is not included in the list"


  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre
  belongs_to :member, class_name: 'Member', foreign_key: :allocator
  has_many :datasets


  #  * Increase used quota counter for a datacentre.
  #  *
  #  * Implementation uses HQL update in order to maintain potential concurrent access (i.e. a datacentre using
  #  * concurrently many API clients. Using HQL update makes sure database row level lock will guarantee only one
  #  * client changes the value at the time.
  #  *
  #  * @param forceRefresh the consequence of using HQL update is lack of the value in the instance field.
  #  * Use ForceRefresh.YES to reread the value from database but be aware that refresh() rereads all fields, not
  #  * only doiQuotaUsed so if you have any other changes in the object persist them first.

  def incQuotaUsed
    # adds a day to the quote used it should trigger after each DOI is created
  end

  # /**
  #  * Check if quota exceeded.
  #  *
  #  * Implementation uses HQL select in order to maintain potential concurrent access (i.e. a datacentre using
  #  * concurrently many API clients.
  #  *
  #  * @return true if quota is exceeded
  #  */
  def isQuotaExceeded
    return false if doi_quota_allowed < 0
    true
  end

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



end
