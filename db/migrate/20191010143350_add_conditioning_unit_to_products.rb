class AddConditioningUnitToProducts < ActiveRecord::Migration
  def up
    add_column :products, :conditioning_unit_id, :integer, index: true
    add_foreign_key :products, :units, column: :conditioning_unit_id

    execute <<-SQL
      UPDATE products AS p
      SET conditioning_unit_id = u.id
      FROM product_nature_variants AS v
        INNER JOIN units AS u
        ON v.default_unit_id = u.base_unit_id
          AND v.default_quantity = u.coefficient
      WHERE p.variant_id = v.id;

      UPDATE product_movements AS m
      SET delta = m.delta * v.default_quantity
      FROM products AS p
        INNER JOIN product_nature_variants AS v
        ON p.variant_id = v.id
      WHERE m.product_id = p.id
        AND p.conditioning_unit_id IS NULL;

      UPDATE products AS p
      SET conditioning_unit_id = v.default_unit_id
      FROM product_nature_variants AS v
      WHERE p.variant_id = v.id
        AND p.conditioning_unit_id IS NULL
    SQL

    # change_column_null :products, :conditioning_unit_id, false
  end

  def down
    # NOOP
  end
end
