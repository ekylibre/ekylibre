class FixPlantVariantIndicator < ActiveRecord::Migration
  # ------------ VARIANTS ------------ 
  # Fix variants with nature name having 'Culture' on its name, they are retrieved with 'nature_ids' and 'variant_ids'
  # The given variants should have a surface indicator set at 1 hectare (as a ProductNatureVariantReading)
  # There are 2 cases : 
  #   1) Reading already exists but is not set correctly, those records are retrieved with 'incorrect_readings' statement and are updated with the 'fix_incorrect_readings' statement
  #   2) Reading doesn't exists on variant, those variants are retrieved with 'variants_without_reading' statement. Readings are created it with 'create_readings' statement which depends on parameters set with 'readings_parameters' statement

  # ------------ PRODUCTS ------------ 
  # Also fix plants associated with the incorrect variants, the given plants are retrieved with 'incorrect_plants' statement
  # The fix is to update the plants population which are initially calculated with square meter unit and not hectare (1 hectare = 10000 square meters). Impacted populations need to be divided by 10000
  # Population is not directly set on products table but on product_movements table
  # The corrects populations are created with 'fix_plant_population' statement which depends on parameters set with 'product_movements_parameters' statement
  
  # SELECT 0 at the end of the request is just here because the request requires an instruction out of the WITH statements

  def up
    execute <<-SQL
      WITH nature_ids AS (
        SELECT id
        FROM product_natures
        WHERE (name ~* '^(Culture)')
      ),
      variant_ids AS (
        SELECT id
        FROM product_nature_variants
        WHERE nature_id IN (SELECT id FROM nature_ids)
      ),
      incorrect_readings AS (
        SELECT id
        FROM product_nature_variant_readings
        WHERE variant_id IN (SELECT id FROM variant_ids)
        AND measure_value_unit != 'hectare'
      ),
      fix_incorrect_readings AS (
        UPDATE product_nature_variant_readings
        SET measure_value_unit = 'hectare', absolute_measure_value_value = 10000, measure_value_value = 1
        WHERE id IN (SELECT id FROM incorrect_readings)
      ),
      variants_without_reading AS (
        SELECT pnv.id
        FROM product_nature_variants AS pnv
        LEFT JOIN product_nature_variant_readings pnvr
        ON pnvr.variant_id = pnv.id
        WHERE pnv.id IN (SELECT id FROM variant_ids)
        AND pnvr.id IS NULL
      ),
      readings_parameters AS (
        SELECT id AS variant_id,
               'hectare' AS measure_value_unit,
               10000 AS absolute_measure_value_value,
               'square_meter' AS absolute_measure_value_unit,
               1 AS measure_value_value,
               'net_surface_area' AS indicator_name,
               'measure' AS indicator_datatype,
               CURRENT_TIMESTAMP AS created_at,
               CURRENT_TIMESTAMP AS updated_at
        FROM product_nature_variants
        WHERE id IN (SELECT id FROM variants_without_reading)
      ),
      create_readings AS (
        INSERT INTO product_nature_variant_readings (variant_id, measure_value_unit, absolute_measure_value_value, absolute_measure_value_unit, measure_value_value, indicator_name, indicator_datatype, created_at, updated_at)
        SELECT * FROM readings_parameters
      ),
      incorrect_plants AS (
        SELECT p.id
        FROM product_nature_variants pnv
        LEFT JOIN product_nature_variant_readings pnvr
        ON pnvr.variant_id = pnv.id
        JOIN products p
        ON p.variant_id = pnv.id
        WHERE (pnvr.id IN (SELECT id FROM incorrect_readings) AND p.type = 'Plant')
        OR pnv.id IN (SELECT id FROM variants_without_reading)
      ),
      product_movements_parameters AS (
        SELECT products.id AS product_id,
               - (product_populations.value - (product_populations.value / 10000)) AS delta,
               CURRENT_TIMESTAMP - ('1 hour'::interval) AS started_at,
               CURRENT_TIMESTAMP - ('1 hour'::interval) + ('1 day'::interval) AS stopped_at,
               0 AS population,
               CURRENT_TIMESTAMP AS created_at,
               CURRENT_TIMESTAMP AS updated_at
        FROM products
        JOIN (SELECT DISTINCT ON (product_id) *
              FROM product_populations
              ORDER BY product_id, started_at DESC) product_populations
        ON product_populations.product_id = products.id
        WHERE products.id IN (SELECT id FROM incorrect_plants)
      ),
      fix_plant_population AS (
        INSERT INTO product_movements (product_id, delta, started_at, stopped_at, population, created_at, updated_at)
        SELECT * FROM product_movements_parameters
      )
      SELECT 0
    SQL
  end

  def down
    #NOOP
  end
end
