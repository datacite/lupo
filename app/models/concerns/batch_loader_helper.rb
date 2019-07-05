module BatchLoaderHelper
  extend ActiveSupport::Concern

  class_methods do
    def load_doi(object)
      # Doi.find_by_id(object.doi).results
      # BatchLoader::Executor.clear_current

      BatchLoader.for(object.uuid).batch do |dois, loader|

        dois = object.doi
        # dois = ["10.17876/musewide/dr.1/05555","10.0166/fk2.stagefigshare.6420615.v1","10.1234/rr763th5wp.1,10.1234/7rdf2ryxjn.1"]
        # Doi.find_by_id(dois).results.each do |doi| 
        #   puts doi.doi
        #   loader.call(object.uuid, [doi]) 
        # end

        results = Doi.find_by_id(dois).results
        loader.call(object.uuid, results) 
      end
    end
  end
end
