# frozen_string_literal: true

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

  before_validation :set_metadata_version, :set_namespace
  before_create { self.created = Time.zone.now.utc.iso8601 }

  def uid
    Base32::URL.encode(id, split: 4, length: 16)
  end

  def doi_id
    doi.doi
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
end
