# frozen_string_literal: true

module Mds
  class IndexController < Mds::ApplicationController
    def login
      render plain: "session cookies not supported", status: :not_implemented
    end
  end
end
