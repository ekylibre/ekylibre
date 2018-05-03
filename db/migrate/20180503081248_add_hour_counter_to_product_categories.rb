class AddHourCounterToProductCategories < ActiveRecord::Migration
  def up
    varieties = [:tractor,
                 :heavy_equipment,
                 :handling_equipment]

    product_natures = ProductNature.where(variety: varieties)

    product_natures.each do |product_nature|
      product_nature.variable_indicators_list << :hour_counter
      product_nature.save!
    end
  end

  def down
  end
end
