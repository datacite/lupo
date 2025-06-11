# frozen_string_literal: true

require "aws-sdk-s3"

class Metadata < ApplicationRecord
  include Bolognese::Utils
  include Bolognese::DoiUtils

  include Cacheable

  alias_attribute :created_at, :created
  alias_attribute :datacite_doi_id, :doi_id

  validates_associated :doi
  validates_presence_of :xml, :namespace
  validate :metadata_must_be_valid

  belongs_to :doi, foreign_key: :dataset, inverse_of: :metadata
  delegate :client, to: :doi

  before_validation :set_namespace
  # We can figure out a new metadata version after it's been validated
  after_validation :set_metadata_version
  before_create { self.created = Time.zone.now.utc.iso8601 }

  before_create :upload_xml_to_s3

  def xml=(value)
    # The encoding is forced here to UTF8
    # because the xml attribute utf-8 encoding was not working as expected and we had failing specs.
    # the failing spec spec/models/metadata_spec.rb:48
    # example 1: Céline was persisted as C\xC3\xA9line.
    # example 2: PatiÃ±o was persisted as Pati\xC3\x83\xC2\xB1o
    # See also the forced return on the getter
    value = value&.force_encoding("UTF-8")
    super(value)
  end

  def xml
    # We check if the value is already set to object_key i.e. externally stored
    # This helps avoid unnecessary calls to S3
    if super == object_key && !object_key.nil?

      bucket_name = ENV["METADATA_STORAGE_BUCKET_NAME"]
      object = Aws::S3::Object.new(bucket_name, object_key)

      if object.exists?
        return object.get.body.read
      end
    end

    # Default return the original value
    # See the setter for information on utf8 encoding
    super&.force_encoding("UTF-8")
  end

  def uid
    Base32::URL.encode(id, split: 4, length: 16)
  end

  def doi_id
    # Don't try and access nil doi object
    # Can occur for example when building the metadata object and the relation
    # hasn't yet been setup
    doi&.doi
  end

  def doi_id=(value)
    r = Doi.find_by(doi: value)
    raise ActiveRecord::RecordNotFound if r.blank?

    self.dataset = r.id
  end

  def client_id
    client.symbol.downcase
  end

  def client_id=(value); end

  def metadata_must_be_valid
    return if doi&.draft? || xml.blank?

    doc = Nokogiri.XML(xml, nil, "UTF-8", &:noblanks)
    return if doc.blank?

    if namespace.blank?
      errors.add(:xml, "XML has no namespace.")
      return
    end

    # load XSD from bolognese gem
    kernel = namespace.to_s.split("/").last
    filepath = File.join(Gem.loaded_specs["bolognese"].full_gem_path, "resources", kernel, "metadata.xsd")
    schema = Nokogiri::XML::Schema(File.open(filepath))
    err = schema.validate(doc).map(&:to_s).join(", ")
    errors.add(:xml, err) if err.present?
  end

  def set_metadata_version
    current_metadata =
      Metadata.where(dataset: dataset).order("created DESC").first
    self.metadata_version =
      current_metadata.present? ? current_metadata.metadata_version + 1 : 0
  end

  def set_namespace
    return nil if xml.blank?

    doc = Nokogiri.XML(xml, nil, "UTF-8", &:noblanks)
    ns =
      doc.collect_namespaces.detect do |_k, v|
        v.start_with?("http://datacite.org/schema/kernel")
      end
    self.namespace = Array.wrap(ns).last
  end

  def upload_xml_to_s3
    bucket_name = ENV["METADATA_STORAGE_BUCKET_NAME"]

    object = Aws::S3::Object.new(bucket_name, object_key)
    object.put(body: xml, content_type: "application/xml")

    # Set the xml attribute to be the object_key
    # this stops the large xml from being persisted but instead just stores
    # a reference to the external storage
    self.xml = object_key

  rescue => e
    Rails.logger.error(e)

    # Raise to rollback transaction and error out attempt
    # This is to prevent a partial storage in db without associated metadata
    # It most likely means a new request needs to be made.
    raise "Failed to upload XML to S3: #{e.message}"
  end

  # This is so we can store unique metadata files in external storage.
  def object_key
    # If we don't have a DOI then best to not try and build a key
    unless doi_id.nil?
      Base64.urlsafe_encode64(doi_id + "_version_" + metadata_version.to_s, padding: false)
    end
  end
end
