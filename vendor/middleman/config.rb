###
# Page options, layouts, aliases and proxies
###

# Default ENV variables
ENV['CDN_URL'] ||= "https://assets.datacite.org"
ENV['RAILS_ENV'] ||= "development"
ENV['SITE_TITLE'] ||= "DataCite REST API"
ENV['SITE_DESCRIPTION'] ||= "The DataCite API."
ENV['TWITTER_HANDLE'] ||= "@datacite"

# Build into /public
set :build_dir, "../../public"

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# General configuration

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

# Load data
activate :data_source do |c|
  c.root = "#{ENV['CDN_URL']}/data"
  c.files = [
    "links.json"
  ]
end

# Set markdown template engine
set :markdown_engine, :pandoc
set :markdown, smartypants: true

# use asset host
activate :asset_host, host: ENV['CDN_URL']

###
# Helpers
###
# Methods defined in the helpers block are available in templates
helpers do
  def stage?
    ENV['RAILS_ENV'] == "stage"
  end
end
