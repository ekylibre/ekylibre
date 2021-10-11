Rails.application.configure do
  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
  # config.i18n.default_locale = :de
  config.i18n.available_locales = %i[eng fra]
  config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
  config.i18n.default_locale = :eng
  config.i18n.locale = :eng
end

I18n.config.enforce_available_locales = false

# Set pluralization active with the algorithms defined in [locale]/i18n.rb
I18n::Backend::Simple.send(:include, I18n::Backend::Pluralization)

def I18n.escape_key(key)
  key.to_s.gsub('.', '-').to_sym
end
