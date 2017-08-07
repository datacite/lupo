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




end
