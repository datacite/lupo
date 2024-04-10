# frozen_string_literal: true

class HashConnection
  class PaginationImplementationMissingError < GraphQL::Error; end

  # @return [Class] The class to use for wrapping items as `edges { ... }`. Defaults to `Connection::Edge`
  def self.edge_class
    self::Edge
  end

  # @return [Object] A list object, from the application. This is the unpaginated value passed into the connection.
  attr_reader :items

  # @return [Object] A list object, from the application. This is the paginated value passed into the connection.
  attr_reader :nodes

  # @return [Object] An object, from the application. This is the meta hash returned from the application.
  attr_reader :meta

  # @return [GraphQL::Query::Context]
  attr_accessor :context

  # @return [Int] An integer, from the application. This is the number of results.
  attr_reader :total_count

  # Raw access to client-provided values. (`max_page_size` not applied to first or last.)
  attr_accessor :after_value, :first_value

  # @return [String, nil] the client-provided cursor. `""` is treated as `nil`.
  def before
    raise PaginationImplementationMissingError, "before is not implemented"
  end

  # @return [String, nil] the client-provided cursor. `""` is treated as `nil`.
  def after
    if defined?(@after)
      @after
    else
      @after = @after_value == "" ? nil : @after_value
    end
  end

  # @param items [Object] some unpaginated collection item, like an `Array` or `ActiveRecord::Relation`
  # @param context [Query::Context]
  # @param first [Integer, nil] The limit parameter from the client, if it provided one
  # @param after [String, nil] A cursor for pagination, if the client provided one
  # @param last [Integer, nil] Limit parameter from the client, if provided
  # @param before [String, nil] A cursor for pagination, if the client provided one.
  # @param max_page_size [Integer, nil] A configured value to cap the result size. Applied as `first` if neither first or last are given.
  def initialize(
    items,
    context: nil,
    first: nil,
    after: nil,
    max_page_size: :not_given,
    last: nil,
    before: nil
  )
    @items = items[:data]
    @context = context
    @nodes = items[:data]
    @first_value = first
    @after_value = decode(after) if after.present?

    @total_count = items.dig(:meta, "total").to_i
    @meta = items[:meta]

    # This is only true if the object was _initialized_ with an override
    # or if one is assigned later.
    @has_max_page_size_override = max_page_size != :not_given
    @max_page_size = max_page_size == :not_given ? nil : max_page_size
  end

  def max_page_size=(new_value)
    @has_max_page_size_override = true
    @max_page_size = new_value
  end

  def max_page_size
    if @has_max_page_size_override
      @max_page_size
    else
      context.schema.default_max_page_size
    end
  end

  def has_max_page_size_override?
    @has_max_page_size_override
  end

  attr_writer :first, :last

  # @return [Integer, nil]
  #   A clamped `first` value.
  #   (The underlying instance variable doesn't have limits on it.)
  #   If neither `first` nor `last` is given, but `max_page_size` is present, max_page_size is used for first.
  def first
    @first ||=
      begin
        capped = limit_pagination_argument(@first_value, max_page_size)
        capped = max_page_size if capped.nil?
        capped
      end
  end

  # @return [Integer, nil] A clamped `last` value. (The underlying instance variable doesn't have limits on it)
  def last
    raise PaginationImplementationMissingError, "last is not implemented"
  end

  # A dynamic alias for compatibility with {Relay::BaseConnection}.
  # @deprecated use {#nodes} instead
  def edge_nodes
    nodes
  end

  # The connection object itself implements `PageInfo` fields
  def page_info
    self
  end

  # @return [Boolean] True if there are more items after this page
  def has_next_page
    nodes&.length < total_count # && !(nodes.length < first.to_i)
  end

  # @return [Boolean] True if there were items before these items
  def has_previous_page
    raise PaginationImplementationMissingError,
          "Implement #{
            self.class
          }#has_previous_page to return the previous-page check"
  end

  # @return [String] The cursor of the first item in {nodes}
  def start_cursor
    nodes.first && encode((after.to_i - 1).to_s)
  end

  # @return [String] The cursor of the last item in {nodes}
  def end_cursor
    nodes.last && encode((after.to_i + 1).to_s)
  end

  # Return a cursor for this item.
  # @param item [Object] one of the passed in {items}, taken from {nodes}
  # @return [String]
  def cursor_for(item)
    raise PaginationImplementationMissingError,
          "Implement #{self.class}#cursor_for(item) to return the cursor for #{
            item.inspect
          }"
  end

  private
    # @param argument [nil, Integer] `first` or `last`, as provided by the client
    # @param max_page_size [nil, Integer]
    # @return [nil, Integer] `nil` if the input was `nil`, otherwise a value between `0` and `max_page_size`
    def limit_pagination_argument(argument, max_page_size)
      if argument
        if argument < 0
          argument = 0
        elsif max_page_size && argument > max_page_size
          argument = max_page_size
        end
      end
      argument
    end

    def decode(cursor)
      context.schema.cursor_encoder.decode(cursor, nonce: true)
    end

    def encode(cursor)
      context.schema.cursor_encoder.encode(cursor, nonce: true)
    end

    # A wrapper around paginated items. It includes a {cursor} for pagination
    # and could be extended with custom relationship-level data.
    class Edge
      def initialize(item, connection)
        @connection = connection
        @item = item
      end

      def node
        @item
      end

      def cursor
        @connection.cursor_for(@item)
      end
    end
end
