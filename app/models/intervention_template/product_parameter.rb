class InterventionTemplate::ProductParameter < ActiveRecord::Base
  belongs_to :intervention_template, class_name: 'InterventionTemplate', foreign_key: :intervention_template_id
  belongs_to :product, class_name: 'Product', foreign_key: :product_id
end
