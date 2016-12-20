# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'tax', 'taxes'
  inflect.irregular 'fax', 'faxes'
  # Although Equipment is always uncountable, we need to have a different for
  # better understanding in code
  inflect.irregular 'equipment', 'equipments'
  inflect.irregular 'abacus', 'abaci'
  inflect.irregular 'fungus', 'fungi'
  inflect.irregular 'maximum', 'maxima'
  inflect.irregular 'minimum', 'minima'
  inflect.irregular 'criterion', 'criteria'
end

# Set pluralization active with the algorithms defined in [locale]/i18n.rb
I18n::Backend::Simple.send(:include, I18n::Backend::Pluralization)

# set config for humanize
Humanize.configure do |config|
  config.default_locale = :en  # [:en, :fr], default: :en
  config.decimals_as = :digits # [:digits, :number], default: :digits
end
