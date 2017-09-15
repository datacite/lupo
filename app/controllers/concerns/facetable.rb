module Facetable
  extend ActiveSupport::Concern

  include do
    def serialize(errors)

    end

    def client_year_facet(params, collection)
      [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(datacentre.created) = ?', params[:year]).count }]
    end


  end
end
