# encoding: utf-8
  
# Set the default source used by mono choices:
# - :foreign_class : Class of foreign object
# - :class : Class of object
# - "variable_name" or :variable_name : A variable (Class name is computed with the name
#     of the variable. Example: "product" will have "Product" class_name. If class_name 
#     has to be different, use next possibility.
# - ["variable_name", "Class"] : Code used to select source with the 
#     class_name of the variable.
# Formize.default_source = :foreign_class
Formize.default_source = ["@current_company", "Company"]

# How many radio can be displayed before to become a +select+
Formize.radio_count_max = 5

# How many select options can be displayed before to become a +unroll+
Formize.select_count_max = 50
