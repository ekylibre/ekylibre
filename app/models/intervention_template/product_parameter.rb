class InterventionTemplate::ProductParameter < ActiveRecord::Base
  # Relation
  belongs_to :intervention_template, class_name: 'InterventionTemplate', foreign_key: :intervention_template_id
  belongs_to :product_nature, class_name: 'ProductNature', foreign_key: :product_nature_id
  belongs_to :product_nature_variant, class_name: 'ProductNatureVariant', foreign_key: :product_nature_variant_id

  # Validation
  validates :quantity, presence: true
  validates :product_nature, presence: true, unless: :product_nature_variant_id?
  validates :product_nature_variant, presence: true, unless: :product_nature_id?


  attr_accessor :product_name

  # Need to access product_name in js
  def attributes
    super.merge(product_name: '')
  end
end
