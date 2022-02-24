class ReferenceRepository < ApplicationRecord
    include Hashid::Rails
    validates_uniqueness_of :re3doi, :allow_nil => true

    def client
        @client ||= Client.find_by_id(self[:client_id])
    end
    def re3repo
        @re3repo ||= DataCatalog.find_by_id(self[:re3doi])
    end
end
