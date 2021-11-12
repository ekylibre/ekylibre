class FixDefaultUnitOnVariant < ActiveRecord::Migration[5.0]
  def up
    # update default unit id on preparation and matter with 'kilogram', 'liter' as default_unit reference name
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_id = (SELECT MIN(id) FROM units WHERE reference_name = pnv.default_unit_name)
      WHERE pnv.default_unit_name IN ('kilogram', 'liter') AND variety IN ('preparation', 'matter')
    SQL

    # update default unit id on seed with 'kilogram' as default_unit where indicator net_mass = 1.0 kilogram
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_id = (SELECT MIN(id) FROM units WHERE reference_name = 'kilogram'),
      default_quantity = 1.0, default_unit_name = 'kilogram'
      FROM product_nature_variant_readings pnvr
      WHERE pnvr.variant_id = pnv.id AND pnvr.indicator_name = 'net_mass'
      AND pnvr.measure_value_unit = 'kilogram' AND pnvr.measure_value_value = 1.0 AND pnv.variety IN ('seed')
    SQL

    # update default unit id on preparation and matter with 'liter' as default_unit where indicator net_volume = 1.0 liter
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_id = (SELECT MIN(id) FROM units WHERE reference_name = 'liter'),
      default_quantity = 1.0, default_unit_name = 'liter'
      FROM product_nature_variant_readings pnvr
      WHERE pnvr.variant_id = pnv.id AND pnvr.indicator_name = 'net_volume'
      AND pnvr.measure_value_unit = 'liter' AND pnvr.measure_value_value = 1.0 AND pnv.variety IN ('preparation', 'matter')
    SQL
  end

  def down
    #nope
  end
end
