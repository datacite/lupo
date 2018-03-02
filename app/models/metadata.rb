class Metadata < ActiveRecord::Base
  include Bolognese::Utils
  include Bolognese::DoiUtils

  include Cacheable

  alias_attribute :created_at, :created
  validates_associated :doi
  validates_presence_of :xml, :namespace
  validate :metadata_must_be_valid

  belongs_to :doi, foreign_key: :dataset

  before_validation :set_metadata_version, :set_namespace
  before_create { self.created = Time.zone.now.utc.iso8601 }

  attr_accessor :regenerate

  def uid
    Base32::URL.encode(id, split: 4, length: 16) if id.present?
  end

  def xml=(value)
    if value.blank?
      write_attribute(:xml, nil)
    else
      input = Base64.decode64(value)
      crosscite = Bolognese::Metadata.new(input: input, regenerate: regenerate)
      write_attribute(:xml, crosscite.datacite)
    end
  end

  def doi_id
    doi.doi
  end

  def doi_id=(value)
    r = Doi.where(doi: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:dataset, r.id)
  end

  def metadata_must_be_valid
    return nil if doi && doi.draft?
    return nil unless xml.present?

    validation_errors
  end

  def validation_errors
    doc = Nokogiri::XML(xml, nil, 'UTF-8', &:noblanks)
    return nil unless doc.present?

    # load XSD from bolognese gem
    self.namespace = doc.namespaces["xmlns"]
    errors.add(:xml, "XML has no namespace.") && return unless namespace.present?

    kernel = namespace.to_s.split("/").last
    filepath = Bundler.rubygems.find_name('bolognese').first.full_gem_path + "/resources/#{kernel}/metadata.xsd"
    schema = Nokogiri::XML::Schema(open(filepath))
    schema.validate(doc).reduce([]) do |sum, error|
      _, _, source, title = error.to_s.split(': ').map(&:strip)
      source = source.split("}").last[0..-2]
      errors.add(source.to_sym, title)
      sum << { source: source, title: title }
      sum
    end
  end

  def validation_errors?
    validation_errors.present?
  end

  def set_metadata_version
    current_metadata = Metadata.where(dataset: dataset).order('metadata.created DESC').first
    self.metadata_version = current_metadata.present? ? current_metadata.metadata_version + 1 : 0
  end

  def set_namespace
    doc = Nokogiri::XML(xml, nil, 'UTF-8', &:noblanks)
    self.namespace = doc && doc.namespaces["xmlns"]
  end
end
