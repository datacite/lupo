# frozen_string_literal: true

class ElasticsearchLoader < GraphQL::Batch::Loader
  def initialize(model)
    @model = model
  end

  def perform(ids)
    @model.query(nil, ids: ids).results.each do |record|
      fulfill(record.uid, record)
    end
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
