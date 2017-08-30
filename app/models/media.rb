class Media < ActiveRecord::Base
  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  attribute :dataset_id
  alias_attribute :uid, :id
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  validates_presence_of :dataset_id, :url, :media_type
  validates_uniqueness_of :uid, message: "This name has already been taken"
  validates_format_of :url, :with => /https?:\/\/[\S]+/ , if: :url?, message: "Website should be an url"
  validates_numericality_of :version, if: :version?

  belongs_to :dataset, class_name: 'Dataset', foreign_key: :dataset
  before_validation :set_dataset
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

  private

  def set_dataset
    r = Dataset.where(doi: dataset_id).first
    fail("dataset_id Not found") unless r.present?
    write_attribute(:dataset, r.id)
  end
end
