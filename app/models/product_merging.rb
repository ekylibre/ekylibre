class ProductMerging < Ekylibre::Record::Base
  belongs_to :product
  belongs_to :originator, class_name: 'InterventionProductParameter'
  belongs_to :merged_with, class_name: 'Product'

  validates :product, presence: true
  validates :merged_with, presence: true

  after_save do
    product.update(dead_at: merged_at)
  end

  before_destroy do
    dead_ats  = Issue.where(target_id: product.id).where.not(observed_at: nil).pluck(:observed_at)
    dead_ats += InterventionTarget.where(product_id: product.id).joins(:intervention).where.not(interventions: { stopped_at: nil }).pluck('interventions.stopped_at')
    product.dead_at = dead_ats.min
  end

  validate do
    unless ProductMerging.where(product: product).where.not(id: id).count.zero?
      errors.add :product, :cannot_merge_product_thats_already_merged
    end
    errors.add :product, :cannot_merge_dead_product if product.dead_at && product.dead_at < merged_at
  end
end
