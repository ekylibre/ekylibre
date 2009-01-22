#I18n.load_path += Dir[ File.join(RAILS_ROOT, 'config', 'locales', '*.{rb,yml}') ]

#puts I18n.load_path.inspect
#I18n.load_path << "#{RAILS_ROOT}/config/locales/fr-FR.yml"


I18n.default_locale = :'fr-FR'

#simple_localization :language => I18n.locale, :class_based_field_error_proc => true, :lang_file_dir => "#{RAILS_ROOT}/config/locales"
