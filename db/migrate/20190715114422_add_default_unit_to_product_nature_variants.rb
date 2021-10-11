class AddDefaultUnitToProductNatureVariants < ActiveRecord::Migration
  def up
    add_column :product_nature_variants, :default_quantity, :decimal, precision: 19, scale: 4, default: 1
    add_column :product_nature_variants, :default_unit_name, :string
    add_column :product_nature_variants, :default_unit_id, :integer, index: true
    add_foreign_key :product_nature_variants, :units, column: :default_unit_id

    execute <<-SQL
      UPDATE product_nature_variants AS v
        SET default_unit_name = (SELECT reference_name FROM units WHERE id = u.base_unit_id LIMIT 1),
            default_unit_id = u.base_unit_id,
            default_quantity = r.measure_value_value * u.coefficient
      FROM product_nature_variant_readings AS r
        INNER JOIN units AS u
          ON r.measure_value_unit = u.reference_name
      WHERE unit_name ~* '(gramme|gram|tonne|ton|quintal|[0-9]\s*(kg|g|mg|t|q))'
        AND r.variant_id = v.id
        AND indicator_name = 'net_mass';

      UPDATE product_nature_variants AS v
        SET default_unit_name = (SELECT reference_name FROM units WHERE id = u.base_unit_id LIMIT 1),
            default_unit_id = u.base_unit_id,
            default_quantity = r.measure_value_value * u.coefficient
      FROM product_nature_variant_readings AS r
        INNER JOIN units AS u
          ON r.measure_value_unit = u.reference_name
      WHERE unit_name ~* '(litre|liter|cube|cubic|[0-9]\s*(l|cl|ml|m³))'
        AND r.variant_id = v.id
        AND indicator_name = 'net_volume';

      UPDATE product_nature_variants AS v
        SET default_unit_name = (SELECT reference_name FROM units WHERE id = u.base_unit_id LIMIT 1),
            default_unit_id = u.base_unit_id,
            default_quantity = r.measure_value_value * u.coefficient
      FROM product_nature_variant_readings AS r
        INNER JOIN units AS u
          ON r.measure_value_unit = u.reference_name
      WHERE unit_name ~* '(acre|are|hectare|carré|square|[0-9]\s*(acre|a|ha|cm²|m²))'
        AND r.variant_id = v.id
        AND indicator_name = 'net_surface_area';

      UPDATE product_nature_variants AS v
        SET default_unit_name = (SELECT reference_name FROM units WHERE id = u.base_unit_id LIMIT 1),
            default_unit_id = u.base_unit_id,
            default_quantity = r.measure_value_value * u.coefficient
      FROM product_nature_variant_readings AS r
        INNER JOIN units AS u
          ON r.measure_value_unit = u.reference_name
      WHERE unit_name ~* '(mètre|meter|[0-9]\s*(m|cm|mm|km))'
        AND r.variant_id = v.id
        AND indicator_name = 'net_length';

      UPDATE product_nature_variants AS v
        SET default_unit_name = (SELECT reference_name FROM units WHERE id = u.base_unit_id LIMIT 1),
            default_unit_id = u.base_unit_id,
            default_quantity = r.measure_value_value * u.coefficient
      FROM product_nature_variant_readings AS r
        INNER JOIN units AS u
          ON r.measure_value_unit = u.reference_name
      WHERE unit_name ~* '(month|mois|day|jour|hour|heure|minute|second|[0-9]\s*(d|h|min|s|ms))'
        AND r.variant_id = v.id
        AND indicator_name = 'usage_duration';

      UPDATE product_nature_variants AS v
        SET default_unit_name = (SELECT reference_name FROM units WHERE id = u.base_unit_id LIMIT 1),
            default_unit_id = u.base_unit_id,
            default_quantity = r.measure_value_value * u.coefficient
      FROM product_nature_variant_readings AS r
        INNER JOIN units AS u
          ON r.measure_value_unit = u.reference_name
      WHERE unit_name ~* '(joule|watt|[0-9]\s*(J|kWh))'
        AND r.variant_id = v.id
        AND indicator_name = 'energy';

      UPDATE product_nature_variants
        SET default_unit_name = 'unity',
            default_quantity = 1,
            default_unit_id = (SELECT id FROM units WHERE reference_name = 'unity' LIMIT 1)
      WHERE default_unit_id IS NULL
    SQL

    change_column_null :product_nature_variants, :unit_name, true
    change_column_null :product_nature_variants, :default_quantity, false
    change_column_null :product_nature_variants, :default_unit_name, false
    change_column_null :product_nature_variants, :default_unit_id, false
  end

  def down
    # NOOP
  end
end
