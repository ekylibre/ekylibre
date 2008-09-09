# = Localized ActiveRecord error messages
# 
# Overwrites the Active Record default error messages with localized ones from
# the language file.
# 
# == Used sections of the language file
# 
# This feature uses the +active_record_messages+ section of the language file
# which simply provides a map with all available localized error messages:
# 
#   active_record_messages:
#     inclusion: is not included in the list
#     exclusion: is reserved
#     invalid: is invalid
#     confirmation: doesn't match confirmation
#     accepted: must be accepted
#     empty: can't be empty
#     blank: can't be blank
#     too_long: is too long (maximum is %d characters)
#     too_short: is too short (minimum is %d characters)
#     wrong_length: is the wrong length (should be %d characters)
#     taken: has already been taken
#     not_a_number: is not a number
# 

ActiveRecord::Errors.default_error_messages = ArkanisDevelopment::SimpleLocalization::CachedLangSectionProxy.new :sections => [:active_record_messages],
  :orginal_receiver => ActiveRecord::Errors.default_error_messages do |localized, orginal|
  orginal.merge localized.symbolize_keys
end
