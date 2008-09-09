# = Localized model and attribute names
# 
# Extends ActiveRecord models to provide a way to specify localized names for models and thier
# attributes. Asume the following model +Computer+ has the attributes +name+, +description+, +ip_address+
# and +user+.
# 
#   class Computer < ActiveRecord::Base
#     belongs_to :user
#     validates_presence_of :name, :ip_address, :user
#     
#     localized_names 'Der Computer',
#       :name => 'Der Name',
#       :description => 'Die Beschreibung',
#       :ip_address => 'Die IP-Adresse',
#       :user => 'Der Besitzer'
#   end
# 
# This stores the localized (in this case german) name of the model and it's attributes in the model
# class. The first parameter is the name of the model followed by a hash defining the localized names
# for the attributes.
# 
# The feature also overwrites ActiveRecords +human_attribute_name+ method to return the localized
# attribute name if available. The model name can be accessed by the class method +localized_model_name+.
# 
#   Computer.localized_model_name               # => 'Der Computer'
#   Computer.human_attribute_name(:ip_address)  # => 'Die IP-Adresse'
# 
# == Used sections of the language file
# 
# This feature does not use sections from the lanuage file.

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module LocalizedModels
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      # This method is used to add localization information to a model. As the
      # first parameter the localized model name is expected. The second
      # parameter is a hash of attribute names, each specifying the localized
      # name of the attribute.
      # 
      # This example adds german names to the model and it's attributes.
      # 
      #   class Computer < ActiveRecord::Base
      #     belongs_to :user
      #     
      #     validates_presence_of :name, :ip_address, :user
      #     
      #     localized_names 'Der Computer',
      #       :name => 'Der Name',
      #       :description => 'Die Beschreibung',
      #       :ip_address => 'Die IP-Adresse',
      #       :user => 'Der Besitzer'
      #     
      #   end
      # 
      # To access the localized model name use the class method
      # +localized_model_name+. The +human_attribute_name+ method will also be
      # extended so you'll get the localized names from it if available.
      def localized_names(model_name, attribute_names = {})
        class << self
          attr_accessor :localized_model_name, :localized_model_collection, :localized_attribute_names
          
          def human_attribute_name(attribute_key_name)
            self.localized_attribute_names[attribute_key_name.to_sym] ||
              self.localized_attribute_names[attribute_key_name.to_s] ||
              super(attribute_key_name.to_s)
          end
        end
        
        self.localized_model_name = model_name
        self.localized_model_collection = attribute_names.delete(:collection) || model_name.pluralize
        self.localized_attribute_names = attribute_names
      end
      
    end
    
  end
end

ActiveRecord::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedModels
