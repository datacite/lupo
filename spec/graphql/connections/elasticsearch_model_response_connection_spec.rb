# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ElasticsearchModelResponseConnection::Edge do
  let(:item) { { id: 1, name: 'test' } }
  let(:connection) { instance_double(ElasticsearchModelResponseConnection) }
  let(:edge) { described_class.new(item, connection) }

  describe '#was_authorized_by_scope_items?' do
    it 'delegates to the connection' do
      allow(connection).to receive(:was_authorized_by_scope_items?).and_return(true)

      expect(edge.was_authorized_by_scope_items?).to be true
      expect(connection).to have_received(:was_authorized_by_scope_items?)
    end

    it 'returns false when connection returns false' do
      allow(connection).to receive(:was_authorized_by_scope_items?).and_return(false)

      expect(edge.was_authorized_by_scope_items?).to be false
    end

    it 'returns nil when connection returns nil' do
      allow(connection).to receive(:was_authorized_by_scope_items?).and_return(nil)

      expect(edge.was_authorized_by_scope_items?).to be nil
    end
  end

  describe '#node' do
    it 'returns the item' do
      expect(edge.node).to eq(item)
    end
  end

  describe '#cursor' do
    it 'delegates to the connection cursor_for method' do
      allow(connection).to receive(:cursor_for).with(item).and_return('encoded_cursor')

      expect(edge.cursor).to eq('encoded_cursor')
      expect(connection).to have_received(:cursor_for).with(item)
    end
  end
end
