# This file contains the default configuration for the features and plugin
# options. It creates the necessary constants to disable preloaded features and
# maintains the list of features which need to be preloaded. It also does some
# environment specific setup stuff.

require File.dirname(__FILE__) + '/language'
require File.dirname(__FILE__) + '/feature_manager'

module ArkanisDevelopment #:nodoc:
  module SimpleLocalization
    
    # An array of features which should not be preloaded. If this constant is
    # already defined it will not be overwritten. This provides a way to
    # exclude features from preloading. You'll just have to define this
    # constant by yourself before the Rails::Initializer.run call in your
    # environment.rb file.
    begin
      SUPPRESS_FEATURES
    rescue NameError
      SUPPRESS_FEATURES = []
    end
    FeatureManager.instance.disable Array(SUPPRESS_FEATURES)
    
    # A list of features loaded directly in the <code>init.rb</code> of the
    # plugin. This is necessary for some features to work with rails observers.
    begin
      PRELOAD_FEATURES
    rescue NameError
      PRELOAD_FEATURES = []
    end
    FeatureManager.instance.preload Array(PRELOAD_FEATURES)
    
    # 
    # Default feature and plugin configuration
    # 
    
    # Mark all features that have to be preloaded to work properly with model
    # observers.
    FeatureManager.instance.preload :localized_models, :localized_application, :localized_application_extensions
    
    # Remove the reload_lang_file feature from the loading list if we're not in
    # the development environment. This feature eats some performance so it
    # should only be used when it's useful and disabled otherwise.
    FeatureManager.instance.disable :reload_lang_file if ENV['RAILS_ENV'] != 'development'
    
    # The localized_templates feature doesn't work well with Rails 2.0. Therfore
    # disable it before it blows up your application.
    FeatureManager.instance.disable :localized_templates if ::Rails::VERSION::MAJOR == 2
    
    # Disable the class_based_field_error_proc feature by defaut since it makes
    # more trouble than profit.
    FeatureManager.instance.disable :class_based_field_error_proc
    
    # Set the debug option to true for the development and test environments.
    # Debug mode will raise nice entry format errors (see localized_application
    # feature) which exactly show whats wrong with an entry. However in a
    # production environment we should avoid these nice HTTP 500 errors...
    Language.debug = true if ENV['RAILS_ENV'] != 'production'
    
  end
end
