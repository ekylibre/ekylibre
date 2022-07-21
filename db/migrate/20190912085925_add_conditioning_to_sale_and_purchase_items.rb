class AddConditioningToSaleAndPurchaseItems < ActiveRecord::Migration[4.2]
  def up
    remove_column :purchase_items, :conditionning
    remove_column :purchase_items, :conditionning_quantity
    remove_column :parcel_item_storings, :conditionning
    remove_column :parcel_item_storings, :conditionning_quantity

    add_column :sale_items, :conditioning_unit_id, :integer, index: true
    add_foreign_key :sale_items, :units, column: :conditioning_unit_id
    add_column :sale_items, :conditioning_quantity, :decimal, precision: 20, scale: 10
    add_reference :sale_items, :catalog_item, index: true

    add_column :purchase_items, :conditioning_unit_id, :integer, index: true
    add_foreign_key :purchase_items, :units, column: :conditioning_unit_id
    add_column :purchase_items, :conditioning_quantity, :decimal, precision: 20, scale: 10
    add_reference :purchase_items, :catalog_item, index: true

    add_column :parcel_item_storings, :conditioning_unit_id, :integer, index: true
    add_foreign_key :parcel_item_storings, :units, column: :conditioning_unit_id
    add_column :parcel_item_storings, :conditioning_quantity, :decimal, precision: 20, scale: 10

    add_column :parcel_items, :conditioning_unit_id, :integer, index: true
    add_foreign_key :parcel_items, :units, column: :conditioning_unit_id
    add_column :parcel_items, :conditioning_quantity, :decimal, precision: 20, scale: 10

    add_reference :catalog_items, :sale_item, index: true
    add_reference :catalog_items, :purchase_item, index: true

    execute <<-SQL
      UPDATE purchase_items AS i
      SET conditioning_unit_id = u.id,
          conditioning_quantity = i.quantity
      FROM product_nature_variants AS v
        INNER JOIN units AS u
        ON v.default_unit_id = u.base_unit_id
          AND v.default_quantity = u.coefficient
      WHERE i.variant_id = v.id;

      UPDATE purchase_items AS i
      SET conditioning_unit_id = v.default_unit_id,
          conditioning_quantity = v.default_quantity * i.quantity
      FROM product_nature_variants AS v
      WHERE i.variant_id = v.id
        AND i.conditioning_unit_id IS NULL
    SQL

    execute <<-SQL
      UPDATE sale_items AS i
      SET conditioning_unit_id = u.id,
          conditioning_quantity = i.quantity
      FROM product_nature_variants AS v
        INNER JOIN units AS u
        ON v.default_unit_id = u.base_unit_id
          AND v.default_quantity = u.coefficient
      WHERE i.variant_id = v.id;

      UPDATE sale_items AS i
      SET conditioning_unit_id = v.default_unit_id,
          conditioning_quantity = v.default_quantity * i.quantity,
          credited_quantity = v.default_quantity * i.credited_quantity
      FROM product_nature_variants AS v
      WHERE i.variant_id = v.id
        AND i.conditioning_unit_id IS NULL
    SQL

    # for storing with product with default unit on variants exist in unit
    execute <<-SQL
      UPDATE parcel_item_storings AS s
      SET conditioning_unit_id = u.id,
          conditioning_quantity = s.quantity
      FROM products AS p
        INNER JOIN product_nature_variants AS v
        ON p.variant_id = v.id
          INNER JOIN units AS u
          ON v.default_unit_id = u.base_unit_id
            AND v.default_quantity = u.coefficient
      WHERE s.product_id = p.id;
    SQL

    # for storing with product with default unit on variants don't exist in unit
    execute <<-SQL
      UPDATE parcel_item_storings AS s
      SET conditioning_unit_id = v.default_unit_id,
          conditioning_quantity = v.default_quantity * s.quantity
      FROM products AS p
        INNER JOIN product_nature_variants AS v
        ON p.variant_id = v.id
      WHERE s.product_id = p.id
        AND s.conditioning_unit_id IS NULL;
    SQL

    # for storing without product
    execute <<-SQL
      UPDATE parcel_item_storings AS s
      SET conditioning_unit_id = v.default_unit_id,
          conditioning_quantity = v.default_quantity * s.quantity
      FROM parcel_items AS pi
        INNER JOIN product_nature_variants AS v
        ON pi.variant_id = v.id
      WHERE s.parcel_item_id = pi.id
        AND s.conditioning_unit_id IS NULL AND s.product_id IS NULL;
    SQL

    execute <<-SQL
      UPDATE parcel_items AS i
      SET conditioning_unit_id = u.id,
          conditioning_quantity = i.population
      FROM product_nature_variants AS v
        INNER JOIN units AS u
        ON v.default_unit_id = u.base_unit_id
          AND v.default_quantity = u.coefficient
      WHERE i.variant_id = v.id
        AND i.role IN ('service', 'fees');

      UPDATE parcel_items AS i
      SET conditioning_unit_id = v.default_unit_id,
          conditioning_quantity = v.default_quantity * i.population
      FROM product_nature_variants AS v
      WHERE i.variant_id = v.id
        AND i.role IN ('service', 'fees')
        AND i.conditioning_unit_id IS NULL
    SQL

    change_column_null :sale_items, :conditioning_unit_id, false
    change_column_null :sale_items, :conditioning_quantity, false
    change_column_null :purchase_items, :conditioning_unit_id, false
    change_column_null :purchase_items, :conditioning_quantity, false
    change_column_null :parcel_item_storings, :conditioning_unit_id, false
    change_column_null :parcel_item_storings, :conditioning_quantity, false
  end

  def down
    # NOOP
  end
end
