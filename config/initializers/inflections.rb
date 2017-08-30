# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular 'media', 'media'
  inflect.irregular 'metadata', 'metadata'
  inflect.uncountable %w( status heartbeat )
end
