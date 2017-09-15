require 'rails_helper'

describe Facetable do

  before do
    class FakesController < ApplicationController
      include Facetable
    end
  end
  after { Object.send :remove_const, :FakesController }
  let(:object) { FakesController.new }

  describe 'client_year_facet' do

    it { puts object.client_year_facet
      expect(object).to eq('expected result') }
  end

end
