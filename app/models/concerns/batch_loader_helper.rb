module BatchLoaderHelper
  extend ActiveSupport::Concern


  included do
    def load_doi(object)      
      logger = Logger.new(STDOUT)
      BatchLoader.for(object).batch do |dois, loader|
        dois = object ### keep this 
        logger.info "Requesting " + object
        results = Doi.find_by_id(dois).results
        loader.call(object, results) 
      end
    end
  end


  # class_methods do
  #   def load_doi(object)
  #     BatchLoader.for(object.uuid).batch do |dois, loader|
  #       dois = object.doi
  #       results = Doi.find_by_id(dois).results
  #       loader.call(object.uuid, results) 
  #     end
  #   end
  # end

end
