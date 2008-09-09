# = Localized models by using the language file
# 
# This feature provides a way to localize ActiveRecord models based on
# translated model and attribute names in the language file. Where the
# +localized_models+ feature depends on translated names written in the
# source code of the models this feature reads all necessary strings from the
# loaded language file.
# 
# This feature is the right choice if your application should support multiple
# languages. If your application is strictly developed for just one language
# +localized_models+ is the better choice.
# 
# To localize a model with this feature just add the necessary section to the
# languge file. How to do this is descriped in the next chapter.
# 
# == Used sections of the language file
# 
# The localized model and attribute names for this feature are located in the
# +models+ section of the language file. The following example localizes the
# +Computer+ model and it's attributes +name+, +description+, +ip_address+ and
# +user+.
# 
#   models:
#     computer:
#       name: Der Computer
#       attributes:
#         name: Der Name
#         description: Die Beschreibung
#         ip_address: Die IP-Adresse
#         user: Der Besitzer
# 
# This feature will convert the name of the model class (+Compuer+) using
# String#underscore (results in +computer+) and will look in the corresponding
# subsection of the +models+ section. Each model section in turn contains the
# name of the model ("Der Computer") and a map translating the model
# attributes.

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module LocalizedModelsByLangFile
    
    # This method adds the +localized_model_name+ and the
    # +human_attribute_name+ to the ActiveRecord::Base class. The original
    # +human_attribute_name+ is still available as +human_attribute_name_without_localization+.
    # 
    # +localized_model_name+ returns the localized model name from the language
    # file. If no localized name is available +nil+ is returned.
    # 
    # The new +human_attribute_name+ looks for the localized name of the
    # attribute. If the language file does not contain a matching entry the
    # requrest will be redirected to the original +human_attribute_name+ method.
    # 
    # Note: since we are extending ActiveRecord::Base it's possible to call both
    # methods directly on the base class (the +scaffold+ method does this indirectly
    # on the +human_attribute_name+ method using Column#human_name). In this case we
    # simply don't know which table or model we belong to and therefore we can't
    # access the localized data. To prevent error messages in this situation
    # ("undefined method `abstract_class?' for Object:Class" because Base#table_name
    # doesn't work here) +localized_model_name+ returns +nil+ and
    # +human_attribute_name+ delegates the request to it's former non localized
    # version (which doesn't need to know the table name because it simply asks the
    # Inflector).
    # 
    # This drawback of the scaffold method is fixed by the
    # localized_column_human_name extension.
    def self.included(base)
      class << base
        
        def localized_model_name
          return nil if self == ActiveRecord::Base
          Language.entry :models, self.to_s.underscore.to_sym, :name
        rescue EntryNotFound
          nil
        end
        
        def localized_model_collection
          return nil if self == ActiveRecord::Base
          collection = Language.entry(:models, self.to_s.underscore.to_sym, :collection)
          
          # if collection is not present (so it's nil)
          unless collection
            name = Language.entry(:models, self.to_s.underscore.to_sym, :name)
            # if name is present (so it's not nil)
            collection = name.pluralize if name
          end
          collection
        rescue EntryNotFound
          nil
        end
        
        alias_method :human_attribute_name_without_localization, :human_attribute_name
        
        def human_attribute_name(attribute_key_name)
          attribute_key_name = attribute_key_name.to_s
          return human_attribute_name_without_localization(attribute_key_name) if self == ActiveRecord::Base
          Language.entry!(:models, self.to_s.underscore.to_sym, :attributes, attribute_key_name)
        rescue EntryNotFound
          human_attribute_name_without_localization(attribute_key_name)
        end
        
      end
    end
    
  end
end

ActiveRecord::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedModelsByLangFile
