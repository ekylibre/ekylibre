class UpdateProductWithoutPopulation < ActiveRecord::Migration
  def change
    Product
    .joins(:nature)
    .where(product_natures: {population_counting: 'unitary'})
    .select { |p| p.population.zero? }.each do |p|
      m = p.movements.build(delta: 1, started_at: Time.now)
      puts m.save!
    end
  end
end
