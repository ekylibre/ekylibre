
I18n.default_locale = :'fr'

simple_localization :language => I18n.locale, :class_based_field_error_proc => true, :lang_file_dir => "#{RAILS_ROOT}/config/locales"
