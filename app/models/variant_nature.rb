class VariantNature < ActiveRecord::Base
  include Lexiconable
  include ScopeIntrospection

  scope :of_class_name, -> (*class_names) { where(nature: class_names) }
end
