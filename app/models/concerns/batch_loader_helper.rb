module BatchLoaderHelper
  extend ActiveSupport::Concern

  class_methods do
    def load_doi(object)

      BatchLoader.for(object.uuid).batch do |dois, loader|

        dois = object.doi
        results = Doi.find_by_id(dois).results
        loader.call(object.uuid, results) 
      end
    end
  end
end
