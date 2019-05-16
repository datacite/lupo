# frozen_string_literal: true

class ActiveRecordLoader < GraphQL::Batch::Loader
  def initialize(model)
    @model = model
  end

  def perform(ids)
    if @model.name == "Prefix"
      @model.where(prefix: ids).each { |record| fulfill(record.id, record) }
    else
      @model.where(id: ids).each { |record| fulfill(record.id, record) }
    end
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
