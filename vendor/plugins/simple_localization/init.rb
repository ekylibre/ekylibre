# Load all source files in the lib directory.
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each do |lib_file|
  require File.expand_path(lib_file)
end

unless File.exists? "#{RAILS_ROOT}/config/initializers/simple_localization.rb"
  # If no initializer is pressent (automatically included by rails) preload any
  # features which have to be ready immediately so they can be used by models
  # which have observers attected to them (which causes them to be loaded before
  # the simple_localization call).
  # 
  # The list of preloaded modules can be modified by simply defining the
  # ArkanisDevelopment::SimpleLocalization::PRELOAD_FEATURES constant by
  # yourself. You have to do this before the Rails::Initializer.run call in your
  # environment.rb file.
  module ArkanisDevelopment::SimpleLocalization #:nodoc:
    
    FeatureManager.instance.freeze_plugin_init_features!
    FeatureManager.instance.plugin_init_features.each do |feature|
      require "#{File.dirname(__FILE__)}/lib/features/#{feature}"
    end
    
  end
end
