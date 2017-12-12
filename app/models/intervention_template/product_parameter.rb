class InterventionTemplate::ProductParameter < ActiveRecord::Base
  belongs_to :intervention_template, class_name: 'InterventionTemplate', foreign_key: :intervention_template_id
  belongs_to :product_nature, class_name: 'ProductNature', foreign_key: :product_nature_id
  belongs_to :product_nature_variant, class_name: 'ProductNatureVariant', foreign_key: :product_nature_variant_id

  validates :quantity, presence: true
  validates :product_nature, presence: true, unless: :product_nature_variant_id?
  validates :product_nature_variant, presence: true, unless: :product_nature_id?
end
