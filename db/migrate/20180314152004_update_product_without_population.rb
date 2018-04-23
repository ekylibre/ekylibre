class UpdateProductWithoutPopulation < ActiveRecord::Migration
  def change
    products_to_change = Product
                         .joins(:nature)
                         .where(product_natures: { population_counting: 'unitary' })
                         .select { |p| p.population.zero? || p.population > 1 }

    products_to_change.each do |product|
      delta = 1 - product.population
      delta = 1 if product.population.zero?

      product
        .movements
        .build(delta: delta, started_at: Time.now)
        .save!
    end
  end
end
