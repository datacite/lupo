class Media < ActiveRecord::Base
  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer

  alias_attribute :uid, :id
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  validates_presence_of  :url, :media_type
  validates_uniqueness_of :uid, message: "This name has already been taken"
  validates_format_of :url, :with => /https?:\/\/[\S]+/ , if: :url?, message: "Website should be an url"
  validates_numericality_of :version, if: :version?
  # validates_inclusion_of :media_type, :in => %w( ROLE_ALLOCATOR ROLE_ADMIN ROLE_DEV ), :message => "Media %s is not included in the list", if: :role_name?

  validate :freeze_uid, :on => :update
  belongs_to :dataset, class_name: 'Dataset', foreign_key: :dataset
  # before_validation :set_dataset
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { where("symbol like ? OR name like ?", "%#{query}%", "%#{query}%") }

  def self.get_all(options={})
    collection = Media

    if options[:year].present?
      years = [{ id: options[:year],
                 title: options[:year],
                 count: collection.where('YEAR(created) = ?', options[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(created) DESC").group("YEAR(created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    if options[:media_type].present?
      media_types = [{ id: options[:media_type],
                 title: options[:media_type],
                 count: collection.where('media_type = ?', options[:media_type]).count }]
    else
      media_types = collection.where.not(created: nil).order("media_type DESC").group("media_type").count
      media_types = media_types.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end
    response = {
      collection: collection,
      media_types: media_types,
      years: years
    }
  end

  def freeze_uid
    errors.add(:uid, "cannot be changed") if self.uid_changed? || self.id_changed?
  end

  def dataset_id=(value)
    r = Dataset.where(doi: value).select(:id, :doi, :datacentre, :created).first
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:dataset, r.id)
  end

  private

  # def set_dataset
  #   r = Dataset.where(doi: dataset_id).first
  #   fail("dataset_id Not found") unless r.present?
  #   write_attribute(:dataset, r.id)
  # end
  #
end
