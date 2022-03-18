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
        id
        client_id
        re3doi
        re3data_url
        created_at
        updated_at
        name
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
    ].map { |method_name| [ method_name, send(method_name)] }.to_h
  end

  def id
    @repository.hashid
  end

  def client_id
    @repository.client_id
  end

  def re3doi
    @repository.re3doi
  end

  def created_at
    @repository.created_at
  end

  def updated_at
    @repository.updated_at
  end

  def name
    @repository.client_repo&.name || @repository.re3_repo&.name
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
    ret = Array.wrap(@repository.re3_repo&.pid_systems).map { |k| k.text }
    ret += Array.wrap(@repository.client_id.nil? ? nil : "DOI")
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
    ret.uniq
  end

  def data_access
    Array.wrap(@repository.re3_repo&.data_accesses).map { |k|
        {
            type: k.type,
            restrictions: Array.wrap(k.restrictions).map{ |r| r.text}
        }
    }
  end

  def data_upload
    Array.wrap(@repository.re3_repo&.data_uploads).map { |k|
        {
            type: k.type,
            restrictions: Array.wrap(k.restrictions).map{ |r| r.text}
        }
    }
  end

  def provider_type
    Array.wrap(@repository.re3_repo&.provider_type).map { |k| k.text }
  end

  def repository_type
    Array.wrap(@repository.re3_repo&.types).map { |k| k.text }
  end

  def subject
    Array.wrap(@repository.re3_repo&.subjects).map { |k|
        id, text = k.text.split(' ', 2)
        {
            id: id,
            text: text,
            scheme: k.scheme
        }
    }
  end
end
