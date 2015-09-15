# This module provides tools to clean app code
# Some tools are generic, others are not.
module Clean
  autoload :Annotations, 'clean/annotations'
  autoload :Locales,     'clean/locales'
  autoload :Support,     'clean/support'
  autoload :Tests,       'clean/tests'
  autoload :Validations, 'clean/validations'
end
