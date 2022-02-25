class ReferenceRepository < ApplicationRecord
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
    include Hashid::Rails

    before_save :force_index

    validates_uniqueness_of :re3doi, :allow_nil => true

    def client_repo
        if @dsclient&.symbol == self[:client_id]
            @dsclient
        else
            @dsclient = ::Client.where(symbol: self[:client_id]).where(deleted_at: nil).first
        end
    end

    def re3_repo
        @re3repo ||= DataCatalog.find_by_id(self[:re3doi]).fetch(:data, []).first
    end

    def as_indexed_json(_options = {})
        ReferenceRepositoryDenormalizer.new(self).to_hash
    end

    settings index: { number_of_shards: 1 } do
        mapping dynamic: 'false' do
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
        end
    end

    def force_index
      __elasticsearch__.instance_variable_set(:@__changed_model_attributes, nil)
    end
end
