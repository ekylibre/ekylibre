# frozen_string_literal: true

class InterventionProposal < ApplicationRecord
  class Parameter < ApplicationRecord
    belongs_to :intervention_proposal, class_name: 'InterventionProposal'
    belongs_to :variant, class_name: 'ProductNatureVariant', foreign_key: :product_nature_variant_id
    belongs_to :product, class_name: 'Product'
    belongs_to :intervention_template_product_parameter, class_name: 'InterventionTemplate::ProductParameter'

    scope :of_product_type, ->(product_type) { where(product_type: product_type) }
  end
end
