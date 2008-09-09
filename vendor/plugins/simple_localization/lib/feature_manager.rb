require 'singleton'

module ArkanisDevelopment #:nodoc:
  module SimpleLocalization #:nodoc:
    
    # A singleton to manage which features should be loaded at what time.
    class FeatureManager
      include Singleton
      
      def initialize
        @all_features = read_available_features
        @plugin_init_features = []
        @frozen_plugin_init_features = nil
        @localization_init_features = []
        @disabled_features = []
      end
      
      # Mark the specified features for preload, meaning it's necessary to load
      # them during plugin initialization.
      def preload(*features)
        @plugin_init_features.concat features.flatten
      end
      
      # Disable the specified features. This removes the these features from the
      # list of available features and from the list of features to preload.
      def disable(*features)
        @disabled_features.concat features.flatten
      end
      
      # Mark the specified features for usual loading when initializing the
      # localization.
      def load(*features)
        @localization_init_features.concat features.flatten
        @disabled_features -= features.flatten
      end
      
      # Returns all available features.
      def all_features
        @all_features
      end
      
      # Returns the features that are requested to be loaded during plugin
      # initialization.
      def plugin_init_features
        @frozen_plugin_init_features || (@all_features & (@plugin_init_features - @disabled_features))
      end
      
      # Returns the features that can be loaded  .
      def localization_init_features
        @all_features & (@localization_init_features - @plugin_init_features - @disabled_features)
      end
      
      # Returns a list of preloaded features the user doesn't want to be loaded.
      def unwanted_features
        plugin_init_features - (@all_features & @localization_init_features)
      end
      
      # Returns a list of all features marked for preload or loading.
      def all_loaded_features
        plugin_init_features + localization_init_features
      end
      
      # Returns the list of disabled features.
      def disabled_features
        @disabled_features
      end
      
      # Freezes the list of features loaded at plugin initialization. After this
      # call no more features can be marked for preload.
      def freeze_plugin_init_features!
        @frozen_plugin_init_features = plugin_init_features
      end
      
      private
      
      def read_available_features
        Dir[File.dirname(__FILE__) + '/features/*.rb'].collect { |path| File.basename(path, '.rb').to_sym }
      end
      
    end
    
  end
end
