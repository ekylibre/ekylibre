class AddTemporalityToCatalogItems < ActiveRecord::Migration
  def up
    add_column    :catalog_items, :started_at, :datetime
    add_column    :catalog_items, :stopped_at, :datetime
    add_column    :catalog_items, :reference_name, :string
    add_reference :catalog_items, :unit, index: true

    execute <<-SQL
      UPDATE catalog_items AS ci
        SET started_at = ci.created_at,
            unit_id = u.id
      FROM product_nature_variants AS v
        INNER JOIN units AS u
          ON v.default_unit_id = u.base_unit_id
            AND v.default_quantity = u.coefficient
      WHERE ci.variant_id = v.id;

      UPDATE catalog_items AS ci
        SET started_at = ci.created_at,
            unit_id = u.id
      FROM product_nature_variants AS v
        INNER JOIN units AS u
          ON u.reference_name = v.default_unit_name
      WHERE ci.variant_id = v.id
        AND ci.unit_id IS NULL
    SQL

    change_column_null :catalog_items, :started_at, false
    change_column_null :catalog_items, :unit_id, false
    remove_index       :catalog_items, name: :index_catalog_items_on_catalog_id_and_variant_id
  end

  def down
    # NOOP
  end
end
