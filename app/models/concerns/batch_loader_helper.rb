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
end
