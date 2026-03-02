# frozen_string_literal: true

class ReferenceRepositoryDenormalizer
  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  def doi_as_url
    doi = @repository.re3doi
    return nil if doi.blank?
    "https://doi.org/#{doi.downcase}"
  end

  def to_hash
    %w[
        uid
        client_id
        re3doi
        re3data_url
        created_at
        updated_at
        name
        alternate_name
        description
        pid_system
        url
        keyword
        contact
        software
        language
        certificate
        data_access
        data_upload
        provider_type
        repository_type
        subject
        re3_created_at
        re3_updated_at
        client_created_at
        client_updated_at
        provider_id
        provider_id_and_name
        year
    ].index_with { |method_name| send(method_name) }
  end

  def uid
    @repository.uid
  end

  def client_id
    @repository.client_id
  end

  def re3doi
    @repository.re3doi
  end

  def name
    @repository.client_repo&.name || @repository.re3_repo&.name
  end

  def alternate_name
    ret = Array.wrap(@repository.re3_repo&.additional_names).map { |name|
      name.text
    }
    ret += Array.wrap(@repository.client_repo&.alternate_name)
    ret.uniq
  end

  def description
    @repository.client_repo&.description || @repository.re3_repo&.description
  end

  def url
    @repository.client_repo&.url || @repository.re3_repo&.url
  end

  def re3data_url
    doi_as_url
  end

  def pid_system
    ret = Array.wrap(@repository.re3_repo&.pid_systems).map { |k| k.text.downcase }
    ret += Array.wrap(@repository.client_id.nil? ? nil : "doi")
    ret.uniq
  end

  def keyword
    ret = Array.wrap(@repository.re3_repo&.keywords).map { |k| k.text }
    ret.uniq
  end

  def contact
    ret = Array.wrap(@repository.re3_repo&.contacts).map { |k| k.text }
    ret.uniq
  end

  def language
    ret = Array.wrap(@repository.re3_repo&.repository_languages).map { |k| k.text }
    ret += Array.wrap(@repository.client_repo&.language)
    ret.uniq
  end

  def certificate
    ret = Array.wrap(@repository.re3_repo&.certificates).map { |k| k.text }
    ret += Array.wrap(@repository.client_repo&.certificate)
    ret.uniq
  end

  def software
    ret = Array.wrap(@repository.re3_repo&.software).map { |k| k.name }
    ret += Array.wrap(@repository.client_repo&.software)
    ret.uniq
  end

  def data_access
    Array.wrap(@repository.re3_repo&.data_accesses).map { |k|
      {
          type: k.type,
          restrictions: Array.wrap(k.restrictions).map { |r| r.text }
      }
    }
  end

  def data_upload
    Array.wrap(@repository.re3_repo&.data_uploads).map { |k|
      {
          type: k.type,
          restrictions: Array.wrap(k.restrictions).map { |r| r.text }
      }
    }
  end

  def provider_type
    Array.wrap(@repository.re3_repo&.provider_types).map { |k| k.text }
  end

  def repository_type
    Array.wrap(@repository.re3_repo&.types).map { |k| k.text }
  end

  def subject
    Array.wrap(@repository.re3_repo&.subjects).map { |k|
      id, text = k.text.split(" ", 2)
      {
          id: id,
          text: text,
          scheme: k.scheme
      }
    }
  end

  def year
    created_at_value = created_at
    return nil if created_at_value.nil?

    Time.parse(created_at_value).year
  end

  def updated_at
    [client_updated_at, re3_updated_at].compact.min
  end

  def created_at
    [client_created_at, re3_created_at].compact.min
  end

  def re3_created_at
    @repository.re3_repo&.created&.to_time(:utc)&.iso8601
  end

  def re3_updated_at
    @repository.re3_repo&.updated&.to_time(:utc)&.iso8601
  end

  def client_created_at
    @repository.client_repo&.created_at&.utc&.iso8601
  end

  def client_updated_at
    @repository.client_repo&.updated_at&.utc&.iso8601
  end

  def provider_id
    @repository.client_repo&.provider_id
  end

  def provider_id_and_name
    @repository.client_repo&.provider_id_and_name
  end
end
