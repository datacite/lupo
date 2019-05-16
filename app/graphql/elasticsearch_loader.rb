# frozen_string_literal: true

class ElasticsearchLoader < GraphQL::Batch::Loader
  def initialize(model)
    @model = model
  end

  def perform(ids)
    @model.find_by_id(ids).results.each { |record| fulfill(record.uid, record) }
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
