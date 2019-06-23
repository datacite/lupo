module BatchLoaderHelper
  extend ActiveSupport::Concern

  class_methods do
    def load_doi(object)
      Doi.find_by_id(object.doi).results
      # BatchLoader.for(object.doi).batch do |dois, loader|
      #   Doi.find_by_id(object.doi).results.each { |doi| loader.call(doi.uid, doi) }
      # end
    end
  end
end
