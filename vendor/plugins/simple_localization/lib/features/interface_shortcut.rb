# = Shortcut module
# 
# This feature makes the contens of the 
# ArkanisDevelopment::SimpleLocalization::Language module accessable in a module
# named <code>Langs</code>. This saves some typing work.
# 
# If the <code>Langs</code> module conflicts with another module just don't load
# this feature by excluding it from the feature list:
# 
#   simple_localization :language => :de, :except => :language_shortcut
# 
# or
# 
#   simple_localization :language => :de, :language_shortcut => false
# 
# 
# == Used sections of the language file
# 
# This feature does not use sections from the lanuage file.
# 

Localization = ArkanisDevelopment::SimpleLocalization::Language
