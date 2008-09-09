# = Localized array extensions
# 
# Localizes the Array#to_sentence method by loading new default options from
# the language file. Please note that this method is added by ActiveSupport and
# not part of Rubys core.
# 
# == Used sections of the language file
# 
#   arrays:
#     to_sentence:
#       connector: and
#       skip_last_comma: false
# 
# The entries of the +to_sentence+ section are used as new options for the
# +to_sentence+ method.

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module LocalizedArray
    
    # Localizes the Array#to_sentence method by using default options from the
    # language file.
    def to_sentence(options = {})
      options = ArkanisDevelopment::SimpleLocalization::Language[:arrays, :to_sentence].symbolize_keys.update(options)
      super options
    end
    
  end
end

Array.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedArray