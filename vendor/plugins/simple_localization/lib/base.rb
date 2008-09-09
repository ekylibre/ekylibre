# This is the base file of the Simple Localization plugin. It is loaded at
# application startup and defines the +simple_localization+ method which should
# be used in the environment.rb file to configure and initialize the
# localization.

# The main method of the SimpleLocalization plugin used to initialize and
# configure the plugin. Usually it is called in the environment.rb file.
# 
#   simple_localization :language => :de, :class_based_field_error_proc => fase
# 
# With the <code>:language</code> option you can specify the name of the
# language file (without extension) you want to use. You can also use the
# options to specify if a specific feature (the files inside the +features+
# directory) should be loaded or not. By default all features will be loaded.
# To prevent a feature from beeing loaded you can specify an option with the
# name of the feature and a value of +false+.
# 
# In the example above this prevents the <code>class_based_field_error_proc</code>
# feature (the <code>class_based_field_error_proc.rb</code> file in the
# <code>features</code> directory) from beeing loaded.
# 
# Alternativly you can specify the <code>:exept</code> option with a list of
# features which should not be loaded:
# 
#   simple_localization :language => :de, :except => [:localized_models, :localized_date_and_time]
# 
# This will load all features except the +localized_models+ and
# +localized_date_and_time+ features. The opposite way (only specify features
# which sould be loaded) is also possible by using the <code>:only</code>
# option.
# 
#   simple_localization :language => :de, :only => [:localized_models, :localized_date_and_time]
# 
# This will only load the +localized_models+ and +localized_date_and_time+
# features, ignoring all others.
# 
# If you use this plugin to localize you application (with the
# +localized_application+ feature) it may also come in handy to move the
# directory containing the language files to a more important place. This can
# be done with the <code>:lang_file_dir</code> option:
# 
#   simple_localization :language => :de, :lang_file_dir => "#{RAILS_ROOT}/app/languages", :only => [:localized_application]
# 
# This example expects the language files in the <code>app/languages</code>
# directory of your rails application. By default the language files are
# located in the +languages+ directory of the Simple Localization plugin.
def simple_localization(options)
  # available options: language, languages, *options (from the Language module), *features
  lang = ArkanisDevelopment::SimpleLocalization::Language
  feature_manager = ArkanisDevelopment::SimpleLocalization::FeatureManager.instance
  lang_options = lang.options.dup
  lang_file_dirs = lang_options.delete :lang_file_dirs
  features = feature_manager.all_features - feature_manager.disabled_features
  
  default_options = {:language => nil, :languages => nil, :lang_file_dir => nil, :lang_file_dirs => nil}.update lang_options
  features.each{|feature| default_options[feature.to_sym] = true}
  options.reverse_merge! default_options
  
  # Analyse the language and lang_file_dir options and add default values if
  # necessary or possible
  languages = [options.delete(:languages), options.delete(:language)].flatten.compact.uniq
  languages << :de if languages.empty?
  lang_file_dirs = [lang_file_dirs, options.delete(:lang_file_dir), options.delete(:lang_file_dirs)].flatten.compact.uniq
  lang_file_dirs << "#{RAILS_ROOT}/app/languages" if File.directory? "#{RAILS_ROOT}/app/languages"
  
  if options[:only]
    feature_manager.load options[:only]
  elsif options[:except]
    feature_manager.load features
    feature_manager.disable options[:except]
  else
    feature_manager.load(options.collect { |feature, enabled| feature if enabled }.compact)
  end
  
  unless feature_manager.unwanted_features.empty?
    RAILS_DEFAULT_LOGGER.warn "Simple Localization plugin configuration:\n" +
      "  You don't want the features #{feature_manager.unwanted_features.join(', ')} to be loaded.\n" +
      "  However to work with rails observers these features are loaded at the end of the plugins init.rb.\n" +
      '  To suppress a preloaded feature please look into the plugins readme file (chapter "Preloaded features").'
  end
  
  # Load the Language module and load the language files and the features
  lang.options.keys.each do |option|
    lang.options[option] = options[option] if options.key? option
  end
  lang.lang_file_dirs = lang_file_dirs
  lang.load(*languages)
  
  feature_manager.localization_init_features.each do |feature|
    require File.dirname(__FILE__) + "/features/#{feature}"
  end
  
  RAILS_DEFAULT_LOGGER.info "Initialized Simple Localization plugin:\n" +
    "  languages: #{languages.join(', ')}\n" +
    "  language file directories: #{lang.lang_file_dirs.join(', ')}\n" +
    "  features: #{feature_manager.all_loaded_features.join(', ')}\n" +
    "  disabled features: #{feature_manager.disabled_features.join(', ')}"
  
  ArkanisDevelopment::SimpleLocalization::Language.loaded_features = feature_manager.localization_init_features
end
