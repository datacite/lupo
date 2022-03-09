# frozen_string_literal: true

class ReferenceRepository < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  include Hashid::Rails

  before_save :force_index

  validates_uniqueness_of :re3doi, allow_nil: true

  def self.find_client(client_id)
    ::Client.where(symbol: client_id).where(deleted_at: nil).first
  end

  def self.find_re3(doi)
    DataCatalog.find_by_id(doi).fetch(:data, []).first
  end

  def client_repo
    if @dsclient&.symbol == self[:client_id]
      @dsclient
    else
      @dsclient = ReferenceRepository.find_client(self[:client_id])
    end
  end

  def re3_repo
    @re3repo ||= ReferenceRepository.find_re3(self[:re3doi])
  end

  def as_indexed_json(_options = {})
    ReferenceRepositoryDenormalizer.new(self).to_hash
  end

  settings index: { number_of_shards: 1 } do
    mapping dynamic: "false" do
      indexes :id
      indexes :client_id
      indexes :re3doi
      indexes :re3data_url
      indexes :created_at, type: :date, format: :date_optional_time
      indexes :updated_at, type: :date, format: :date_optional_time
      indexes :name
      indexes :description
      indexes :pid_system, type: :keyword
      indexes :url
      indexes :keyword, type: :keyword
      indexes :subject
      indexes :contact
      indexes :language, type: :keyword
      indexes :certificate, type: :keyword
      indexes :data_access, type: :keyword
      indexes :data_upload, type: :keyword
      indexes :provider_type, type: :keyword
      indexes :repository_type, type: :keyword
      indexes :data_upload_licenses, type: :keyword
      indexes :software, type: :keyword
    end
  end

  def force_index
    __elasticsearch__.instance_variable_set(:@__changed_model_attributes, nil)
  end
end
