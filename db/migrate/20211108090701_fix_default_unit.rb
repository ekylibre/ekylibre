class FixDefaultUnit < ActiveRecord::Migration[5.0]

  def up
    # update default unit on phytosanitary variant net_mass
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_name = pnvr.absolute_measure_value_unit,
      default_quantity = pnvr.absolute_measure_value_value
      FROM product_nature_variant_readings pnvr
      WHERE pnvr.variant_id = pnv.id AND pnvr.indicator_name = 'net_mass'
      AND pnv.default_unit_name = 'unity' AND variety = 'preparation' AND france_maaid IS NOT NULL
    SQL

    # update default unit on phytosanitary variant net_volume
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_name = pnvr.absolute_measure_value_unit,
      default_quantity = pnvr.absolute_measure_value_value
      FROM product_nature_variant_readings pnvr
      WHERE pnvr.variant_id = pnv.id AND pnvr.indicator_name = 'net_volume'
      AND pnv.default_unit_name = 'unity' AND variety = 'preparation' AND france_maaid IS NOT NULL
    SQL

    # update default unit on other phytosanitary with net_mass and net_volume
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_name = pnvri.absolute_measure_value_unit,
      default_quantity = pnvri.absolute_measure_value_value
      FROM product_nature_variant_readings pnvr, product_nature_variant_readings pnvri
      WHERE pnvr.variant_id = pnv.id AND pnvr.indicator_name = 'net_volume'
      AND pnvri.variant_id = pnv.id AND pnvri.indicator_name = 'net_mass' AND pnvri.absolute_measure_value_unit = 'kilogram'
      AND pnv.default_unit_name = 'unity' AND variety = 'preparation' AND france_maaid IS NOT NULL
    SQL

    # update default unit on other variant ('preparation', 'matter') with net_mass
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_name = pnvr.absolute_measure_value_unit,
      default_quantity = pnvr.absolute_measure_value_value
      FROM product_nature_variant_readings pnvr
      WHERE pnvr.variant_id = pnv.id AND pnvr.indicator_name = 'net_mass'
      AND pnv.default_unit_name = 'unity' AND variety IN ('preparation', 'matter') AND france_maaid IS NULL
    SQL

    # update default unit on other variant ('preparation', 'matter') with net_volume
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_name = pnvr.absolute_measure_value_unit,
      default_quantity = pnvr.absolute_measure_value_value
      FROM product_nature_variant_readings pnvr
      WHERE pnvr.variant_id = pnv.id AND pnvr.indicator_name = 'net_volume'
      AND pnv.default_unit_name = 'unity' AND variety IN ('preparation', 'matter') AND france_maaid IS NULL
    SQL

    # update default unit on other variant ('preparation', 'matter') with net_mass and net_volume
    execute <<-SQL
      UPDATE product_nature_variants pnv
      SET default_unit_name = pnvri.absolute_measure_value_unit,
      default_quantity = pnvri.absolute_measure_value_value
      FROM product_nature_variant_readings pnvr, product_nature_variant_readings pnvri
      WHERE pnvr.variant_id = pnv.id AND pnvr.indicator_name = 'net_volume'
      AND pnvri.variant_id = pnv.id AND pnvri.indicator_name = 'net_mass' AND pnvri.absolute_measure_value_unit = 'kilogram'
      AND pnv.default_unit_name = 'unity' AND variety IN ('preparation', 'matter') AND france_maaid IS NULL
    SQL
  end

  def down
    #nope
  end
end
