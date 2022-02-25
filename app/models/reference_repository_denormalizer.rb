class ReferenceRepositoryDenormalizer
    attr_reader :repository

    def initialize(repository)
        @repository = repository
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
        @repository.client_repo&.name || @repository.re3_repo.name
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
        ret += Array.wrap(@repository.client_id.nil? ? nil : 'DOI')
        ret.uniq
    end

    def doi_as_url
        doi = @repository.re3doi
        return nil if doi.blank?
        "https://doi.org/#{doi.downcase}"
    end


end
