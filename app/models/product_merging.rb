class ProductMerging < Ekylibre::Record::Base
  belongs_to :product
  belongs_to :originator, class_name: 'InterventionProductParameter'
  belongs_to :merged_with, class_name: 'Product'

  validates :product, presence: true
  validates :merged_with, presence: true

  after_save do
    product.update(dead_at: merged_at)
  end

  validate do
    unless ProductMerging.where(product: product).where.not(id: id).count.zero?
      errors.add :product, :cannot_merge_product_thats_already_merged
    end
  end
end
