class ProductMerging < Ekylibre::Record::Base
  belongs_to :product
  belongs_to :originator, class_name: 'InterventionProductParameter'
  belongs_to :merged_with, class_name: 'Product'

  after_save do
    product.update(dead_at: merged_at)
  end
end
