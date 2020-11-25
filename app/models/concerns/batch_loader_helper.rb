# frozen_string_literal: true

module BatchLoaderHelper
  extend ActiveSupport::Concern
  ### TODO: remove after benchmark
  class_methods do
    def load_doi(object)
      BatchLoader.for(object.uuid).batch do |dois, loader|
        dois = object.doi
        results = Doi.find_by(ids: dois).results
        loader.call(object.uuid, results)
      end
    end
  end
end
