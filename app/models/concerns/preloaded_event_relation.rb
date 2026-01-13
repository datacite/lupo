# frozen_string_literal: true

# Wrapper class to make preloaded event arrays compatible with ActiveRecord::Relation API
# This allows existing code that calls methods like `pluck`, `map`, `select` to work
# with in-memory arrays without modification.
class PreloadedEventRelation
  include Enumerable

  def initialize(events)
    @events = Array(events)
  end

  # Delegate Enumerable methods to the underlying array
  def each(&block)
    @events.each(&block)
  end

  # Implement pluck to match ActiveRecord::Relation#pluck behavior
  # Supports single or multiple column names
  def pluck(*column_names)
    if column_names.length == 1
      column_name = column_names.first
      @events.map { |event| event.public_send(column_name) }
    else
      @events.map { |event| column_names.map { |col| event.public_send(col) } }
    end
  end

  # Delegate map to the underlying array
  def map(&block)
    @events.map(&block)
  end

  # Delegate select to the underlying array
  def select(&block)
    PreloadedEventRelation.new(@events.select(&block))
  end

  # Delegate other common Enumerable methods
  def compact
    PreloadedEventRelation.new(@events.compact)
  end

  def uniq
    PreloadedEventRelation.new(@events.uniq)
  end

  def sort_by(&block)
    PreloadedEventRelation.new(@events.sort_by(&block))
  end

  def group_by(&block)
    @events.group_by(&block)
  end

  def inject(initial = nil, &block)
    @events.inject(initial, &block)
  end

  def length
    @events.length
  end

  def empty?
    @events.empty?
  end

  def present?
    @events.present?
  end

  def blank?
    @events.blank?
  end

  # Allow direct access to the underlying array
  def to_a
    @events
  end

  def to_ary
    @events
  end
end
