class AddConstraintBetweenProductAndCategory < ActiveRecord::Migration[4.2]
  def change

    execute <<-SQL
      UPDATE products p
      SET category_id = v.category_id
      FROM product_nature_variants v
      WHERE p.variant_id = v.id
      AND p.category_id NOT IN ( SELECT id FROM product_nature_categories );
    SQL

    add_foreign_key :products, :product_nature_categories, column: :category_id
  end
end
