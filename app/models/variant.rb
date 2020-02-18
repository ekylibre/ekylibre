class Variant < ActiveRecord::Base
  include Lexiconable
  include ScopeIntrospection

  belongs_to :variant_category
  belongs_to :variant_type

  scope :of_class_name, -> (*class_names) { where(class_name: class_names) }
  scope :of_sub_nature, -> (*sub_natures) { where(sub_nature: sub_natures) }
end
