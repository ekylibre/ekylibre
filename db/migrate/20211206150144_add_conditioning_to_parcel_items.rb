class AddConditioningToParcelItems < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      UPDATE parcel_items AS i
      SET conditioning_unit_id = p.conditioning_unit_id,
          conditioning_quantity = i.population
      FROM products AS p
      WHERE i.source_product_id IS NOT NULL 
        AND p.id = i.source_product_id
        AND i.conditioning_unit_id IS NULL;
    SQL
  end
end
