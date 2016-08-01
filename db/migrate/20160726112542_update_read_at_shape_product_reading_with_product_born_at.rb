class UpdateReadAtShapeProductReadingWithProductBornAt < ActiveRecord::Migration
  def up
    execute "UPDATE product_readings SET read_at = products.born_at FROM products WHERE product_readings.product_id = products.id AND product_readings.id IN (SELECT product_readings.id FROM product_readings, products WHERE product_readings.indicator_name='shape' AND product_readings.product_id = products.id AND product_readings.read_at != products.born_at GROUP BY product_readings.product_id, product_readings.id ORDER BY product_readings.read_at)"
  end
end
