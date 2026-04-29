# frozen_string_literal: true

require "maremma"
require "benchmark"

class Doi < ApplicationRecord
  self.ignored_columns += [:publisher]
  PUBLISHER_JSON_SCHEMA = Rails.root.join("app", "models", "schemas", "doi", "publisher.json")
  audited only: %i[doi url creators contributors titles publisher_obj publication_year types descriptions container sizes formats version_info language dates identifiers related_identifiers related_items funding_references geo_locations rights_list subjects schema_version content_url landing_page aasm_state source reason]

  # disable STI
  self.inheritance_column = :_type_disabled

  include Metadatable
  include Cacheable
  include Dateable
  include Rorable

  # include helper module for generating random DOI suffixes
  include Helpable

  include Modelable

  # include helper module for converting and exposing metadata
  include Crosscitable

  # include state machine
  include AASM

  # include helper module for Elasticsearch
  include Indexable

  # include helper module for sending emails
  include Mailable

  include Elasticsearch::Model

  include Enrichable

  aasm whiny_transitions: false do
    # draft is initial state for new DOIs.
    state :draft, initial: true
    state :tombstoned, :registered, :findable, :flagged, :broken

    event :register do
      transitions from: [:draft], to: :registered, if: [:registerable?]
    end

    event :publish do
      transitions from: [:draft], to: :findable, if: [:registerable?]
      transitions from: :registered, to: :findable
    end

    event :hide do
      transitions from: [:findable], to: :registered
    end

    event :show do
      transitions from: [:registered], to: :findable
    end

    event :flag do
      transitions from: %i[registered findable], to: :flagged
    end

    event :link_check do
      transitions from: %i[tombstoned registered findable flagged], to: :broken
    end
  end

  self.table_name = "dataset"

  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  alias_attribute :registered, :minted
  alias_attribute :state, :aasm_state

  attr_accessor :current_user

  attribute :regenerate, :boolean, default: false
  attribute :only_validate, :boolean, default: false
  attribute :should_validate, :boolean, default: false
  attribute :publisher, :string, default: nil

  attr_accessor :skip_client_domains_validation
  attr_accessor :skip_schema_version_validation

  belongs_to :client, foreign_key: :datacentre, optional: true
  has_many :media, -> { order "created DESC" }, class_name: "Media", foreign_key: :dataset, dependent: :destroy, inverse_of: :doi
  has_many :metadata, -> { order "created DESC" }, class_name: "Metadata", foreign_key: :dataset, dependent: :destroy, inverse_of: :doi
  has_many :view_events, -> { where target_relation_type_id: "views" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :download_events, -> { where target_relation_type_id: "downloads" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :reference_events, -> { where source_relation_type_id: "references" }, class_name: "Event", primary_key: :doi, foreign_key: :source_doi, dependent: :destroy
  has_many :citation_events, -> { where target_relation_type_id: "citations" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :part_events, -> { where source_relation_type_id: "parts" }, class_name: "Event", primary_key: :doi, foreign_key: :source_doi, dependent: :destroy
  has_many :part_of_events, -> { where target_relation_type_id: "part_of" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :version_events, -> { where source_relation_type_id: "versions" }, class_name: "Event", primary_key: :doi, foreign_key: :source_doi, dependent: :destroy
  has_many :version_of_events, -> { where target_relation_type_id: "version_of" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :activities, as: :auditable, dependent: :destroy
  # has_many :source_events, class_name: "Event", primary_key: :doi, foreign_key: :source_doi, dependent: :destroy
  # has_many :target_events, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy

  has_many :references, class_name: "Doi", through: :reference_events, source: :doi_for_target
  has_many :citations, class_name: "Doi", through: :citation_events, source: :doi_for_source
  has_many :parts, class_name: "Doi", through: :part_events, source: :doi_for_target
  has_many :part_of, class_name: "Doi", through: :part_of_events, source: :doi_for_source
  has_many :versions, class_name: "Doi", through: :version_events, source: :doi_for_target
  has_many :version_of, class_name: "Doi", through: :version_of_events, source: :doi_for_source
  has_many :enrichments, class_name: "Enrichment", foreign_key: :doi, primary_key: :doi, inverse_of: :doi_record

  delegate :provider, to: :client, allow_nil: true

  validates_presence_of :doi
  validates_presence_of :url, if: Proc.new { |doi| doi.is_registered_or_findable? }

  json_schema_validation = {
    message: ->(errors) { errors },
    schema: PUBLISHER_JSON_SCHEMA
  }

  def validate_publisher_obj?(doi)
    doi.validatable? && doi.publisher_obj? && !(doi.publisher_obj.blank? || doi.publisher_obj.all?(nil))
  end

  validates :publisher_obj, if: ->(doi) { validate_publisher_obj?(doi) }, json: json_schema_validation

  # from https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but using uppercase
  validates_format_of :doi, with: /\A10\.\d{4,5}\/[-._;()\/:a-zA-Z0-9*~$=]+\z/, on: :create
  validates_format_of :url, with: /\A(ftp|http|https):\/\/\S+/, if: :url?, message: "URL is not valid"
  validates_uniqueness_of :doi, message: "This DOI has already been taken", unless: :only_validate
  validates_inclusion_of :agency, in: %w(datacite crossref kisti medra istic jalc airiti cnki op), allow_blank: true
  validates :last_landing_page_status, numericality: { only_integer: true }, if: :last_landing_page_status?
  validates :xml, presence: true, xml_schema: true, if: Proc.new { |doi| doi.validatable? }
  validate :check_url, if: Proc.new { |doi| doi.is_registered_or_findable? && !skip_client_domains_validation }
  validate :check_dates, if: :dates?
  validate :check_rights_list, if: :rights_list?
  validate :check_titles, if: :titles?
  validate :check_descriptions, if: :descriptions?
  validate :check_types, if: :types?
  validate :check_container, if: :container?
  validate :check_subjects, if: :subjects?
  validate :check_creators, if: :creators?
  validate :check_contributors, if: :contributors?
  validate :check_landing_page, if: :landing_page?
  validate :check_identifiers, if: :identifiers?
  validate :check_related_identifiers, if: :related_identifiers?
  validate :check_related_items, if: :related_items?
  validate :check_funding_references, if: :funding_references?
  validate :check_geo_locations, if: :geo_locations?
  validate :check_language, if: :language?

  after_commit :update_url, on: %i[create update]
  after_commit :update_media, on: %i[create update]

  before_validation :update_publisher, if: [ :will_save_change_to_publisher? ]
  before_validation :update_xml, if: :regenerate
  before_validation :update_agency
  before_validation :update_field_of_science
  before_validation :update_language, if: :language?
  before_validation :update_rights_list, if: :rights_list?
  before_validation :update_identifiers
  before_validation :update_types
  before_validation :update_geo_locations
  before_save :set_defaults, :save_metadata
  before_create { self.created = Time.zone.now.utc.iso8601 }

  FIELD_OF_SCIENCE_SCHEME = "Fields of Science and Technology (FOS)"

  scope :q, ->(query) { where("dataset.doi = ?", query) }

  # use different index for testing
  if Rails.env.test?
    index_name "dois-test#{ENV['TEST_ENV_NUMBER']}"
  elsif ENV["ES_PREFIX"].present?
    index_name "dois-#{ENV['ES_PREFIX']}"
  else
    index_name "dois"
  end

  # (rest of file unchanged)

  # Ensure Bolognese metadata is populated from stored DataCite XML.
  # Bolognese RDF writers build a graph from `meta`; in Lupo `meta` is an
  # in-memory instance variable and isn't persisted in the database.
  #
  # This is intentionally local-only (no network calls): we parse the record's
  # own `xml` field.
  def ensure_bolognese_meta!
    return meta if meta.present?
    return meta if xml.blank?

    @meta = parse_xml(xml, doi: doi)
  end

  def rdf_xml
    ensure_bolognese_meta!
    raise ActionController::UnknownFormat, "RDF representation is not available for this DOI" if graph.nil?

    super
  end

  def turtle
    ensure_bolognese_meta!
    raise ActionController::UnknownFormat, "RDF representation is not available for this DOI" if graph.nil?

    super
  end
end
