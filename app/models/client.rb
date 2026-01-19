# frozen_string_literal: true

class Client < ApplicationRecord
  SUBJECTS_JSON_SCHEMA = Rails.root.join("app", "models", "schemas", "client", "subjects.json")
  audited except: %i[
    system_email
    service_contact
    globus_uuid
    salesforce_id
    password
    updated
    comments
    experiments
    version
    doi_quota_allowed
    doi_quota_used
    created
  ]

  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for managing associated users
  include Userable

  # include helper module for setting password
  include Passwordable

  # include helper module for authentication
  include Authenticable

  # include helper module for Elasticsearch
  include Indexable

  # include helper module for sending emails
  include Mailable

  include Elasticsearch::Model

  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  self.table_name = "datacentre"

  alias_attribute :flipper_id, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  alias_attribute :contact_email, :system_email
  attr_readonly :symbol
  delegate :symbol, to: :provider, prefix: true
  delegate :consortium_id, to: :provider, allow_nil: true
  delegate :salesforce_id, to: :provider, prefix: true, allow_nil: true

  attr_accessor :password_input, :target_id
  attr_reader :from_salesforce

  validate :subjects_only_for_disciplinary_repos
  validates :subjects, if: :subjects?,
            json: {
              message: ->(errors) { errors },
              schema: SUBJECTS_JSON_SCHEMA
            }

  validates_presence_of :symbol, :name, :system_email
  validates_uniqueness_of :symbol,
                          message: "This Client ID has already been taken"
  validates_format_of :symbol,
                      with: /\A([A-Z]+\.[A-Z0-9]+(-[A-Z0-9]+)?)\Z/,
                      message:
                        "should only contain capital letters, numbers, and at most one hyphen"
  validates_length_of :symbol, minimum: 5, maximum: 18
  validates_format_of :system_email,
                      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_format_of :salesforce_id,
                      with: /[a-zA-Z0-9]{18}/,
                      message: "wrong format for salesforce id",
                      if: :salesforce_id?
  validates_inclusion_of :role_name,
                         in: %w[ROLE_DATACENTRE],
                         message: "Role %s is not included in the list"
  validates_inclusion_of :client_type,
                         in: %w[repository periodical igsnCatalog raidRegistry],
                         message: "Client type %s is not included in the list"
  validates_associated :provider
  validate :check_id, on: :create
  validate :check_prefix, on: :create
  validate :freeze_symbol, on: :update
  validate :check_issn, if: :issn?
  validate :check_certificate, if: :certificate?
  validate :check_repository_type, if: :repository_type?
  validate :uuid_format, if: :globus_uuid?
  strip_attributes

  belongs_to :provider, foreign_key: :allocator, touch: true
  has_many :dois, foreign_key: :datacentre
  has_many :client_prefixes, dependent: :destroy
  has_many :prefixes, through: :client_prefixes
  has_many :provider_prefixes, through: :client_prefixes
  has_many :activities, as: :auditable, dependent: :destroy

  before_validation :set_defaults
  before_validation :convert_subject_hashes_to_camelcase
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
  after_create_commit :assign_prefix
  after_create_commit :create_reference_repository
  after_update_commit :update_reference_repository
  after_destroy_commit :destroy_reference_repository
  after_commit on: %i[update] do
    ::Client.import_dois(self.id)
  end

  # use different index for testing
  if Rails.env.test?
    index_name "clients-test#{ENV['TEST_ENV_NUMBER']}"
  elsif ENV["ES_PREFIX"].present?
    index_name "clients-#{ENV['ES_PREFIX']}"
  else
    index_name "clients"
  end

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: {
          tokenizer: "keyword", filter: %w[lowercase ascii_folding]
        },
      },
      normalizer: {
        keyword_lowercase: { type: "custom", filter: %w[lowercase] },
      },
      filter: {
        ascii_folding: {
          type: "asciifolding", preserve_original: true
        },
      },
    },
  } do
    mapping dynamic: "false" do
      indexes :id, type: :keyword
      indexes :uid, type: :keyword, normalizer: "keyword_lowercase"
      indexes :symbol, type: :keyword
      indexes :provider_id, type: :keyword
      indexes :provider_id_and_name, type: :keyword
      indexes :consortium_id, type: :keyword
      indexes :re3data_id, type: :keyword
      indexes :opendoar_id, type: :integer
      indexes :salesforce_id, type: :keyword
      indexes :globus_uuid, type: :keyword
      indexes :issn,
              type: :object,
              properties: {
                issnl: { type: :keyword },
                electronic: { type: :keyword },
                print: { type: :keyword },
              }
      indexes :prefix_ids, type: :keyword
      indexes :name,
              type: :text,
              fields: {
                keyword: { type: "keyword" },
                raw: {
                  type: "text", analyzer: "string_lowercase", "fielddata": true
                },
              }
      indexes :alternate_name,
              type: :text,
              fields: {
                keyword: { type: "keyword" },
                raw: {
                  type: "text", analyzer: "string_lowercase", "fielddata": true
                },
              }
      indexes :description, type: :text
      indexes :system_email,
              type: :text, fields: { keyword: { type: "keyword" } }
      indexes :service_contact,
              type: :object,
              properties: {
                email: { type: :text },
                given_name: { type: :text },
                family_name: { type: :text },
              }
      indexes :certificate, type: :keyword
      indexes :language, type: :keyword
      indexes :repository_type, type: :keyword
      indexes :version, type: :integer
      indexes :is_active, type: :keyword
      indexes :domains, type: :text
      indexes :year, type: :integer
      indexes :url, type: :text, fields: { keyword: { type: "keyword" } }
      indexes :software,
              type: :text,
              fields: {
                keyword: { type: "keyword" },
                raw: {
                  type: "text", analyzer: "string_lowercase", "fielddata": true
                },
              }
      indexes :cache_key, type: :keyword
      indexes :client_type, type: :keyword
      indexes :created, type: :date
      indexes :updated, type: :date
      indexes :deleted_at, type: :date
      indexes :analytics_dashboard_url, type: :text
      indexes :analytics_tracking_id, type: :text
      indexes :cumulative_years, type: :integer, index: "false"
      indexes :subjects, type: :object, properties: {
        subjectScheme: { type: :keyword },
        subject: { type: :keyword },
        schemeUri: { type: :keyword },
        valueUri: { type: :keyword },
        lang: { type: :keyword },
        classificationCode: { type: :keyword },
      }

      # include parent objects
      indexes :provider,
              type: :object,
              properties: {
                id: { type: :keyword },
                uid: { type: :keyword },
                symbol: { type: :keyword },
                globus_uuid: { type: :keyword },
                client_ids: { type: :keyword },
                prefix_ids: { type: :keyword },
                name: {
                  type: :text,
                  fields: {
                    keyword: { type: "keyword" },
                    raw: {
                      type: "text",
                      "analyzer": "string_lowercase",
                      "fielddata": true,
                    },
                  },
                },
                display_name: {
                  type: :text,
                  fields: {
                    keyword: { type: "keyword" },
                    raw: {
                      type: "text",
                      "analyzer": "string_lowercase",
                      "fielddata": true,
                    },
                  },
                },
                system_email: {
                  type: :text, fields: { keyword: { type: "keyword" } }
                },
                group_email: {
                  type: :text, fields: { keyword: { type: "keyword" } }
                },
                version: { type: :integer },
                is_active: { type: :keyword },
                year: { type: :integer },
                description: { type: :text },
                website: {
                  type: :text, fields: { keyword: { type: "keyword" } }
                },
                logo_url: { type: :text },
                region: { type: :keyword },
                focus_area: { type: :keyword },
                organization_type: { type: :keyword },
                member_type: { type: :keyword },
                consortium_id: {
                  type: :text,
                  fields: {
                    keyword: { type: "keyword" },
                    raw: {
                      type: "text",
                      "analyzer": "string_lowercase",
                      "fielddata": true,
                    },
                  },
                },
                consortium_organization_ids: { type: :keyword },
                country_code: { type: :keyword },
                role_name: { type: :keyword },
                cache_key: { type: :keyword },
                joined: { type: :date },
                twitter_handle: { type: :keyword },
                ror_id: { type: :keyword },
                salesforce_id: { type: :keyword },
                billing_information: {
                  type: :object,
                  properties: {
                    postCode: { type: :keyword },
                    state: { type: :text },
                    organization: { type: :text },
                    department: { type: :text },
                    city: { type: :text },
                    country: { type: :text },
                    address: { type: :text },
                  },
                },
                technical_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                secondary_technical_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                billing_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                secondary_billing_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                service_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                secondary_service_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                voting_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                created: { type: :date },
                updated: { type: :date },
                deleted_at: { type: :date },
                cumulative_years: { type: :integer, index: "false" },
                consortium: { type: :object },
                consortium_organizations: { type: :object },
              }
    end
  end

  def as_indexed_json(options = {})
    {
      "id" => uid,
      "uid" => uid,
      "provider_id" => provider_id,
      "provider_id_and_name" => provider_id_and_name,
      "consortium_id" => consortium_id,
      "re3data_id" => re3data_id,
      "opendoar_id" => opendoar_id,
      "salesforce_id" => salesforce_id,
      "globus_uuid" => globus_uuid,
      "issn" => issn,
      "prefix_ids" => options[:exclude_associations] ? nil : prefix_ids,
      "name" => name,
      "alternate_name" => alternate_name,
      "description" => description,
      "certificate" => Array.wrap(certificate),
      "symbol" => symbol,
      "year" => year,
      "language" => Array.wrap(language),
      "repository_type" => Array.wrap(repository_type),
      "service_contact" => service_contact,
      "system_email" => system_email,
      "domains" => domains,
      "url" => url,
      "software" => software,
      "is_active" => is_active,
      "password" => password,
      "cache_key" => cache_key,
      "client_type" => client_type,
      "created" => created.try(:iso8601),
      "updated" => updated.try(:iso8601),
      "deleted_at" => deleted_at.try(:iso8601),
      "cumulative_years" => cumulative_years,
      "provider" =>
        if options[:exclude_associations]
          nil
        else
          provider.as_indexed_json(exclude_associations: true)
        end,
      "analytics_dashboard_url" => analytics_dashboard_url,
      "analytics_tracking_id" => analytics_tracking_id,
      "subjects" => Array.wrap(subjects),
    }
  end

  def self.query_fields
    %w[
      uid^10
      symbol^10
      name^5
      description^5
      system_email^5
      url
      software^3
      repository.subjects.text^3
      repository.certificates.text^3
      _all
    ]
  end

  def self.query_aggregations
    {
      years: {
        date_histogram: {
          field: "created",
          interval: "year",
          format: "year",
          order: { _key: "desc" },
          min_doc_count: 1,
        },
        aggs: { bucket_truncate: { bucket_sort: { size: 10 } } },
      },
      cumulative_years: {
        terms: {
          field: "cumulative_years",
          size: 20,
          min_doc_count: 1,
          order: { _count: "asc" },
        },
      },
      providers: {
        terms: { field: "provider_id_and_name", size: 10, min_doc_count: 1 },
      },
      software: {
        terms: { field: "software.keyword", size: 10, min_doc_count: 1 },
      },
      client_types: {
        terms: { field: "client_type", size: 10, min_doc_count: 1 },
      },
      repository_types: {
        terms: { field: "repository_type", size: 10, min_doc_count: 1 },
      },
      certificates: {
        terms: { field: "certificate", size: 10, min_doc_count: 1 },
      },
    }
  end

  def csv
    client = {
      name: name,
      client_id: symbol,
      provider_id: provider.present? ? provider.symbol : "",
      salesforce_id: salesforce_id,
      consortium_salesforce_id: provider.present? ? provider.salesforce_id : "",
      is_active: is_active == "\x01",
      created: created,
      updated: updated,
      re3data_id: re3data_id,
      client_type: client_type,
      alternate_name: alternate_name,
      description: description,
      url: url,
      software: software,
      system_email: system_email,
    }.values

    CSV.generate { |csv| csv << client }
  end

  def uid
    symbol.downcase
  end

  def from_salesforce=(value)
    @from_salesforce = (value.to_s == "true")
  end

  # workaround for non-standard database column names and association
  def provider_id
    provider_symbol.downcase
  end

  def provider_id_and_name
    "#{provider_id}:#{provider.name}"
  end

  def provider_id=(value)
    r = Provider.where(symbol: value).first
    return nil if r.blank?

    write_attribute(:allocator, r.id)
  end

  def re3data=(value)
    attr = value.present? ? value[16..-1] : nil
    write_attribute(:re3data_id, attr)
  end

  def subjects=(value)
    write_attribute(:subjects, Array.wrap(value).uniq)
  end

  def opendoar=(value)
    attr = value.present? ? value[38..-1] : nil
    write_attribute(:opendoar_id, attr)
  end

  def prefix_ids
    prefixes.pluck(:uid)
  end

  def target_id=(value)
    c = self.class.find_by_id(value)
    return nil if c.blank?

    client_target = c.records.first
    Rails.logger.info "[Transfer] with target client #{client_target.symbol}"

    Doi.transfer(client_id: symbol.downcase, client_target_id: client_target.id)
  end

  # use keyword arguments consistently
  def transfer(provider_target_id: nil)
    if provider_target_id.blank?
      Rails.logger.error "[Transfer] No target provider provided."
      return nil
    end

    target_provider =
      Provider.where(
        "role_name IN (?)",
        %w[ROLE_ALLOCATOR ROLE_CONSORTIUM_ORGANIZATION],
      ).
        where(symbol: provider_target_id).
        first

    if target_provider.blank?
      Rails.logger.error "[Transfer] Provider doesn't exist."
      return nil
    end

    Rails.logger.info "[Transfer] Client transfer starting from #{provider_id} to #{target_provider.id}"

    # Transfer client
    update_attribute(:allocator, target_provider.id)

    # transfer prefixes
    transfer_prefixes(provider_target_id: target_provider.symbol)

    # Update DOIs
    TransferClientJob.perform_later(
      self,
      provider_target_id: provider_target_id,
    )
  end

  # use keyword arguments consistently
  def transfer_prefixes(provider_target_id: nil)
    # These prefixes are used by multiple clients
    prefixes_to_keep = %w[10.4124 10.4225 10.4226 10.4227]

    # delete all associated prefixes
    associated_prefixes =
      prefixes.reject { |prefix| prefixes_to_keep.include?(prefix.uid) }
    prefix_ids = associated_prefixes.pluck(:id)
    prefixes_names = associated_prefixes.pluck(:uid)

    if prefix_ids.present?
      response = ProviderPrefix.where("prefix_id IN (?)", prefix_ids).destroy_all
      Rails.logger.info "[Transfer][Prefix] #{response.count} provider prefixes deleted. #{prefix_ids}"

      response = ClientPrefix.where("prefix_id IN (?)", prefix_ids).destroy_all
      Rails.logger.info "[Transfer][Prefix] #{response.count} client prefixes deleted. #{prefix_ids}"
    end

    # Assign prefix(es) to provider and client
    prefixes_names.each do |prefix|
      provider_prefix =
        ProviderPrefix.create(
          provider_id: provider_target_id, prefix_id: prefix,
        )
      Rails.logger.info "[Transfer][Prefix] Provider prefix for provider #{
                          provider_target_id
                        } and prefix #{prefix} created."

      ClientPrefix.create(
        client_id: symbol,
        provider_prefix_id: provider_prefix.uid,
        prefix_id: prefix,
      )
      Rails.logger.info "[Transfer][Prefix] Client prefix for client #{symbol} and prefix #{
                          prefix
                        } created."
    end
  end

  def service_contact_email
    service_contact.fetch("email", nil) if service_contact.present?
  end

  def service_contact_given_name
    service_contact.fetch("given_name", nil) if service_contact.present?
  end

  def service_contact_family_name
    service_contact.fetch("family_name", nil) if service_contact.present?
  end

  # def index_all_dois
  #   Doi.index(from_date: "2011-01-01", client_id: id)
  # end

  def cache_key
    "clients/#{uid}-#{updated.iso8601}"
  end

  def password_input=(value)
    write_attribute(:password, encrypt_password_sha256(value)) if value.present?
  end

  # backwards compatibility
  def member
    Provider.where(symbol: provider_id).first if provider_id.present?
  end

  def year
    created_at.year if created_at.present?
  end

  # count years account has been active. Ignore if deleted the same year as created
  def cumulative_years
    if deleted_at && deleted_at.year > created_at.year
      (created_at.year...deleted_at.year).to_a
    elsif deleted_at
      []
    else
      (created_at.year..Date.today.year).to_a
    end
  end

  def to_jsonapi
    response =
      DataciteDoi.query(
        nil,
        client_id: uid, state: "findable,registered", page: { size: 0, number: 1 }, totals_agg: "client_export",
      )
    doi_counts = response.aggregations.clients_totals.buckets.first
    dois_total = doi_counts ? doi_counts.doc_count : 0
    dois_current_year = doi_counts ? doi_counts.this_year.buckets.dig(0, "doc_count") : 0
    dois_last_year = doi_counts ? doi_counts.last_year.buckets.dig(0, "doc_count") : 0

    attributes = {
      "symbol" => symbol,
      "name" => name,
      "description" => description,
      "system_email" => system_email,
      "url" => url,
      "re3data_id" => re3data_id,
      "provider_id" => provider_id,
      "provider_salesforce_id" => provider_salesforce_id,
      "is_active" => is_active.getbyte(0) == 1,
      "dois_total" => dois_total,
      "dois_current_year" => dois_current_year,
      "dois_last_year" => dois_last_year,
      "created" => created.try(:iso8601),
      "updated" => updated.try(:iso8601),
      "deleted_at" => deleted_at ? deleted_at.try(:iso8601) : nil,
    }

    { "id" => symbol.downcase, "type" => "clients", "attributes" => attributes }
  end

  def self.export(query: nil)
    # Loop through all clients
    i = 0
    page = { size: 1_000, number: 1 }
    response = self.query(query, include_deleted: true, page: page)
    response.records.each do |client|
      client.send_client_export_message(client.to_jsonapi)
      i += 1
    end

    total = response.results.total
    total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

    # keep going for all pages
    page_num = 2
    while page_num <= total_pages
      page = { size: 1_000, number: page_num }
      response = self.query(query, include_deleted: true, page: page)
      response.records.each do |client|
        client.send_client_export_message(client.to_jsonapi)
        i += 1
      end
      page_num += 1
    end

    "#{i} clients exported."
  end

  def self.export_doi_counts(query: nil)
    # Loop through all clients
    page = { size: 1_000, number: 1 }
    response = self.query(query, page: page)
    clients = response.results.to_a

    total = response.results.total
    total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

    # keep going for all pages
    page_num = 2
    while page_num <= total_pages
      page = { size: 1_000, number: page_num }
      response = self.query(query, page: page)
      clients = clients + response.results.to_a
      page_num += 1
    end

    # Get doi counts via DOIs query and combine next to clients.
    response =
      DataciteDoi.query(
        nil,
        page: { size: 0, number: 1 }, totals_agg: "client_export",
      )

    client_totals = {}
    totals_buckets = response.aggregations.clients_totals.buckets
    totals_buckets.each do |totals|
      client_totals[totals["key"]] = { "count" => totals["doc_count"] }
    end

    headers = [
      "Repository Name",
      "Repository ID",
      "Organization",
      "DOIs in Index",
      "DOIs in Database",
      "DOIs missing",
    ]

    dois_by_client = DataciteDoi.group(:datacentre).count
    rows =
      clients.reduce([]) do |sum, client|
        db_total = dois_by_client[client.id.to_i].to_i
        es_total =
          client_totals[client.uid] ? client_totals[client.uid]["count"] : 0
        if (db_total - es_total) > 0
          # Limit for salesforce default of max 80 chars
          name = +client.name.truncate(80)
          # Clean the name to remove quotes, which can break csv parsers
          name.gsub!(/["']/, "")

          row = {
            accountName: name,
            fabricaAccountId: client.symbol,
            parentFabricaAccountId:
              client.provider.present? ? client.provider.symbol : nil,
            doisCountTotal: es_total,
            doisDbTotal: db_total,
            doisMissing: db_total - es_total,
          }.values

          sum << CSV.generate_line(row)
        end

        sum
      end

    title = if Rails.env.stage?
      if ENV["ES_PREFIX"].present?
        "DataCite Fabrica Stage"
      else
        "DataCite Fabrica Test"
      end
    else
      "DataCite Fabrica"
    end

    if rows.blank?
      message = "Found 0 repositories with DOIs not indexed."
      Rails.logger.warn message
      self.send_notification_to_slack(message, title: title + ": DOIs in Elasticsearch", level: "good")
      return nil
    end

    csv = [CSV.generate_line(headers)] + rows

    total_missing = rows.reduce(0) do |sum, row|
      sum = sum + row.split(",").last.to_i
      sum
    end

    message = "Found #{csv.size - 1} repositories with #{total_missing} DOIs not indexed."
    Rails.logger.warn message
    self.send_notification_to_slack(message, title: title + ": DOIs in Elasticsearch", level: "warning")

    csv.join("")
  end

  def self.import_dois(client_id, options = {})
    if client_id.blank?
      Rails.logger.error "Missing client ID."
      exit
    end
    DoiImportByClientJob.perform_later(client_id)
  end

  # import all DOIs not indexed in Elasticsearch
  def self.import_dois_not_indexed(query: nil)
    table = CSV.parse(export_doi_counts(query: query), headers: true)

    # loop through repositories that have DOIs not indexed in Elasticsearch
    table.each do |row|
      Rails.logger.info "Started import of #{row["DOIs in Database"]} DOIs (#{row["DOIs missing"]} missing) for repository #{row["Repository ID"]}."
      DoiImportByClientJob.perform_later(row["Repository ID"])
    end
  end

  protected
    def check_issn
      Array.wrap(issn).each do |i|
        if !i.is_a?(Hash)
          errors.add(:issn, "ISSN should be an object and not a string.")
        elsif i["issnl"].present?
          unless /\A\d{4}(-)?\d{3}[0-9X]+\z/.match?(i["issnl"])
            errors.add(:issn, "ISSN-L #{i['issnl']} is in the wrong format.")
          end
        end
        if i["electronic"].present?
          unless /\A\d{4}(-)?\d{3}[0-9X]+\z/.match?(i["electronic"])
            errors.add(
              :issn,
              "ISSN (electronic) #{i['electronic']} is in the wrong format.",
            )
          end
        end
        if i["print"].present?
          unless /\A\d{4}(-)?\d{3}[0-9X]+\z/.match?(i["print"])
            errors.add(
              :issn,
              "ISSN (print) #{i['print']} is in the wrong format.",
            )
          end
        end
      end
    end

    def check_language
      Array.wrap(language).each do |l|
        errors.add(:issn, "Language can't be empty.") if l.blank?
      end
    end

    def check_certificate
      Array.wrap(certificate).each do |c|
        unless [
          "CoreTrustSeal",
          "DIN 31644",
          "DINI",
          "DSA",
          "RatSWD",
          "WDS",
          "CLARIN",
        ].include?(c)
          errors.add(
            :certificate,
            "Certificate #{
            c
          } is not included in the list of supported certificates.",
          )
        end
      end
    end

    def check_repository_type
      Array.wrap(repository_type).each do |r|
        unless %w[
          disciplinary
          governmental
          institutional
          multidisciplinary
          project-related
          other
        ].include?(r)
          errors.add(
            :repository_type,
            "Repository type #{
            r
          } is not included in the list of supported repository types.",
          )
        end
      end
    end

    def uuid_format
      unless UUID.validate(globus_uuid)
        errors.add(:globus_uuid, "#{globus_uuid} is not a valid UUID")
      end
    end

    def freeze_symbol
      errors.add(:symbol, "cannot be changed") if symbol_changed?
    end

    def subjects_only_for_disciplinary_repos
      if Array.wrap(subjects).any? && Array.wrap(repository_type).exclude?("disciplinary")
        errors.add(
          :subjects,
          "Subjects are only allowed for disciplinary repositories.  This repository_type is: #{repository_type}",
        )
      end
    end

    def check_id
      if symbol && symbol.split(".").first != provider.symbol
        errors.add(
          :symbol,
          ", Your Client ID must include the name of your provider. Separated by a dot '.' ",
        )
      end
    end

    def get_prefix
      provider_prefix = (provider.present? && provider.provider_prefixes.present?) ? provider.provider_prefixes.select { |_provider_prefix| (_provider_prefix.state == "without-repository") }.first : nil
      prefix = Prefix.all.count > 0 ? Prefix.where.missing(:client_prefixes).merge(Prefix.where.missing(:provider_prefixes)).first : nil

      provider_prefix || prefix || nil
    end

    def check_prefix
      if !get_prefix
        errors.add(
          :base,
          "No prefixes available.  Unable to create repository.",
        )
      end
    end

    def assign_prefix
      available_prefix = get_prefix
      if !available_prefix
        errors.add(
          :base,
          "No prefixes available.  Created repository, but a prefix was not assigned.  Contact support to get a prefix.",
        )
      else
        prefix, provider_prefix = nil
        available_prefix.class.name == "Prefix" ? prefix = available_prefix : provider_prefix = available_prefix

        if !provider_prefix.present?
          provider_prefix = ProviderPrefix.create(
            provider_id: provider.symbol, prefix_id: prefix.uid
          )
        end

        ClientPrefix.create(
          client_id: symbol,
          provider_prefix_id: provider_prefix.uid,
          prefix_id: provider_prefix.prefix.uid
        )
      end
    end

    def user_url
      ENV["VOLPINO_URL"] + "/users?client-id=" + symbol.downcase
    end

  private
    def set_defaults
      self.domains = "*" if domains.blank?
      self.client_type = "repository" if client_type.blank?
      self.issn = {} if issn.blank? || client_type == "repository"
      self.certificate = [] if certificate.blank? || client_type == "periodical"
      if repository_type.blank? || client_type == "periodical"
        self.repository_type = []
      end
      self.is_active = is_active ? "\x01" : "\x00"
      self.version = version.present? ? version + 1 : 0
      self.role_name = "ROLE_DATACENTRE" if role_name.blank?
      self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
      self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
    end

    def convert_subject_hashes_to_camelcase
      if self.subjects?
        self.subjects = Array.wrap(self.subjects).map { |subject|
          subject.transform_keys! do |key|
            key.to_s.camelcase(:lower)
          end
        }
      else
        []
      end
    end

    def create_reference_repository
      ReferenceRepository.create_from_client(self)
    end

    def update_reference_repository
      ReferenceRepository.update_from_client(self)
    end

    def destroy_reference_repository
      ReferenceRepository.destroy_from_client(self)
    end
end
