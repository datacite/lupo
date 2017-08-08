class Dataset < ApplicationRecord
  attribute :datacenter_id
  alias_attribute :datacenter_id, :datacentre
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  belongs_to :datacenter, class_name: 'Datacenter', foreign_key: :datacentre
  self.table_name = "dataset"

  validates_presence_of :doi, :datacentre
  validates_format_of :doi, :with => /(10\.\d{4,5})\/.+\z/
  validates_uniqueness_of :doi, message: "This DOI has already been taken"
  validates_numericality_of :version, if: :version?

  before_create :is_quota_exceeded
  after_create  :decrease_doi_quota

  def self.get_all(options={})

    collection = Dataset
    collection = collection.query(options[:query]) if options[:query]

    if options[:datacenter].present?
      collection = collection.where(datacentre: options[:datacenter])
      @datacenter = collection.where(datacentre: options[:datacenter]).group(:datacenter).count.first
    end

    if options[:datacenter].present?
      datacenters = [{ id: options[:datacenter],
                 datacenter: options[:datacenter],
                 count: Dataset.where(datacentre: options[:datacenter]).count }]
    else
      datacenters = Dataset.where.not(datacentre: nil).order("datacentre DESC").group(:datacentre).count
      datacenters = datacenters.map { |k,v| { id: k.to_s, datacenter: k.to_s, count: v } }
    end
    #
    page = options[:page] || { number: 1, size: 1000 }
    #
    @datasets = Dataset.order(:datacentre).page(page[:number]).per_page(page[:size])
    @datasets
  end

  def is_quota_exceeded
    datacenter = Datacenter.find(self.datacenter_id)
    fail("You have excceded your DOI quota. You cannot mint DOIs anymore.") if datacenter[:doi_quota_allowed] < 0
  end

  def decrease_doi_quota
    datacenter = Datacenter.find(self.datacenter_id)
    fail("Something went wrong when decreasing your DOI quota") unless Datacenter.update(datacenter[:id], doi_quota_allowed: datacenter[:doi_quota_allowed] - 1)
  end

end
