require 'middleman-core/load_paths'
::Middleman.setup_load_paths

require 'middleman-core'
require 'middleman-core/rack'

require 'fileutils'

app = ::Middleman::Application.new

run ::Middleman::Rack.new(app).to_app
