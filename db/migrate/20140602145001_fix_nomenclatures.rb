class FixNomenclatures < ActiveRecord::Migration
  def replace_items_in_array(table, column, options = {})
    conditions = '1=1'
    if options[:reference_name]
      conditions = "reference_name = '#{options[:reference_name]}'"
    end

    # ex of column = abilities_list
    say "replace item in array #{table}##{column}  #{options.inspect}"

    if options[:old] && options[:new]
      execute("UPDATE #{table} SET #{column} = REPLACE(#{column}, '#{options[:old]}', '#{options[:new]}') WHERE #{column} LIKE '%#{options[:old]}%' AND #{conditions}")
    elsif options[:new]
      execute("UPDATE #{table} SET #{column} = COALESCE(NULLIF(#{column}, '') || ', #{options[:new]}',  '#{options[:new]}') WHERE #{conditions}")
    elsif options[:old]
      execute("UPDATE #{table} SET #{column} = REPLACE(REPLACE(REPLACE(#{column}, ', #{options[:old]}', ''), '#{options[:old]}', ''), '#{options[:old]},', '') WHERE #{conditions}")
    else
      fail StandardException
    end
  end

  PRODUCT_NATURE_VARIANT_ITEMS = [
    { table: 'product_nature_variants', column: 'reference_name', old: 'alfalfa_seed', new: 'lucerne_seed' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:bth_s_arezzo_r1_gau__red_lat_s25kg', new: 'coop:bth_s_arezzo_r1_gau_red_lat_s25kg' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:bth_s_arezzo_r1_gau__red_lat_s25kg', new: 'coop:bth_s_ascott_r1_gau__red_s25kg' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:bth_s_caphorn_r1_gau__red_lat_s25kg', new: 'coop:bth_s_caphorn_r1_gau_red_lat_s25kg' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:bth_s_rubisko_r1_gau_red_25kg', new: 'coop:bth_s_rubisko_r1_gau___red_s25kg' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:bd_s_miradoux_r1_gau_red_net_25kg', new: 'coop:bd_s_miradoux_r1_gau_red_25kg' },

    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:ammonitre_27__vr', new: 'coop:ammonitre_27_____vr' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:ammonitre_33_5__vr', new: 'coop:ammonitre_33_5_____vr' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:ammonitre_33_5__bb', new: 'coop:ammonitre_33_5_____bb' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:chlorure_60__gr_vr', new: 'coop:chlorure_60__gr____vr' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:adexar_5_l', new: 'coop:adexar_5l' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:kalao_d__5dl', new: 'coop:kalao_d__5_l' }
  ]

  PRODUCT_NATURE_VARIANT_READING_ITEMS = [
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'potassium_concentration', reference_name: 'bulk_ammonitrate_33' },
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'phosphorus_concentration', reference_name: 'bulk_ammonitrate_33' },
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'potassium_concentration', reference_name: 'coop:ammonitre_27_____vr' },
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'phosphorus_concentration', reference_name: 'coop:ammonitre_27_____vr' },
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'potassium_concentration', reference_name: 'coop:ammonitre_33_5_____vr' },
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'phosphorus_concentration', reference_name: 'coop:ammonitre_33_5_____vr' },
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'potassium_concentration', reference_name: 'coop:ammonitre_33_5_____bb' },
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'phosphorus_concentration', reference_name: 'coop:ammonitre_33_5_____bb' },

    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'nitrogen_concentration', reference_name: 'coop:super_46__gr__vr' },
    { table: 'product_nature_variant_readings', old_frozen_indicator_name: 'potassium_concentration', reference_name: 'coop:super_46__gr__vr' },

    { table: 'product_nature_variant_readings', column: 'indicator_name', new_value: 'phosphorus_concentration', old_value: 'potassium_concentration', reference_name: 'liquid_10_34_d1.4' },
    { table: 'product_nature_variant_readings', column: 'indicator_name', new_value: 'phosphorus_concentration', old_value: 'potassium_concentration', reference_name: 'liquid_10_25_d1.4' }

  ]

  PRODUCT_READING_ITEMS = [
    { table: 'product_readings', column: 'indicator_name', old_value: 'potassium_concentration', reference_name: 'bulk_ammonitrate_33' },
    { table: 'product_readings', column: 'indicator_name', old_value: 'phosphorus_concentration', reference_name: 'bulk_ammonitrate_33' },
    { table: 'product_readings', column: 'indicator_name', old_value: 'potassium_concentration', reference_name: 'coop:ammonitre_27_____vr' },
    { table: 'product_readings', column: 'indicator_name', old_value: 'phosphorus_concentration', reference_name: 'coop:ammonitre_27_____vr' },
    { table: 'product_readings', column: 'indicator_name', old_value: 'potassium_concentration', reference_name: 'coop:ammonitre_33_5_____vr' },
    { table: 'product_readings', column: 'indicator_name', old_value: 'phosphorus_concentration', reference_name: 'coop:ammonitre_33_5_____vr' },
    { table: 'product_readings', column: 'indicator_name', old_value: 'potassium_concentration', reference_name: 'coop:ammonitre_33_5_____bb' },
    { table: 'product_readings', column: 'indicator_name', old_value: 'phosphorus_concentration', reference_name: 'coop:ammonitre_33_5_____bb' },

    { table: 'product_readings', column: 'indicator_name', old_value: 'potassium_concentration', reference_name: 'coop:super_46__gr__vr' },
    { table: 'product_readings', column: 'indicator_name', old_value: 'nitrogen_concentration', reference_name: 'coop:super_46__gr__vr' },
    { table: 'product_readings', column: 'indicator_name', new_value: 'phosphorus_concentration', old_value: 'potassium_concentration', reference_name: 'liquid_10_25_d1.4' },
    { table: 'product_readings', column: 'indicator_name', new_value: 'phosphorus_concentration', old_value: 'potassium_concentration', reference_name: 'liquid_10_34_d1.4' }

  ]

  INTERVENTIONS = [
    { table: 'interventions', column: 'reference_name', old: 'base-implant-0', new: 'base-implanting-0' },
    { table: 'interventions', column: 'natures', old: 'implant', new: 'implanting' }
  ]

  def up
    # check if product_nature is present in DB and update it with new values
    for item in PRODUCT_NATURE_VARIANT_ITEMS
      replace_items_in_array(item[:table], item[:column], item)
    end

    for item in PRODUCT_NATURE_VARIANT_READING_ITEMS
      next unless variant_id = connection.select_value("SELECT min(id) FROM product_nature_variants WHERE reference_name = '#{item[:reference_name]}'").to_i
      if item[:old_frozen_indicator_name] && item[:new_frozen_indicator_name]
        fail NotImplemented
      elsif item[:new_frozen_indicator_name]
        if item[:new_frozen_indicator_datatype] == 'measure'
          execute("INSERT INTO #{item[:table]} (variant_id, indicator_name, indicator_datatype, measure_value_value, measure_value_unit, absolute_measure_value_value, absolute_measure_value_unit, created_at, updated_at) VALUES ('#{variant_id}', '#{item[:new_frozen_indicator_name]}', '#{item[:new_frozen_indicator_datatype]}', '#{item[:new_value]}', '#{item[:new_unit]}', '#{item[:new_absolute_value]}', '#{item[:new_absolute_unit]}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
        end
      elsif item[:new_value] && item[:old_value]
        execute("UPDATE #{item[:table]} SET #{item[:column]} = '#{item[:new_value]}' WHERE #{item[:column]} = '#{item[:old_value]}' AND variant_id = #{variant_id}")
      elsif item[:old_frozen_indicator_name]
        execute("DELETE FROM #{item[:table]} WHERE indicator_name = '#{item[:old_frozen_indicator_name]}' AND variant_id = #{variant_id}")
      end
    end

    for item in PRODUCT_READING_ITEMS
      next unless variant_id = connection.select_value("SELECT min(id) FROM product_nature_variants WHERE reference_name = '#{item[:reference_name]}'").to_i
      if item[:new_value] && item[:old_value]
        execute("UPDATE #{item[:table]} SET #{item[:column]} = '#{item[:new_value]}' WHERE #{item[:column]} = '#{item[:old_value]}' AND product_id IN (SELECT id FROM products WHERE variant_id = #{variant_id})")
      elsif item[:old_value]
        execute("DELETE FROM #{item[:table]} WHERE #{item[:column]} = '#{item[:old_value]}' AND product_id IN (SELECT id FROM products WHERE variant_id = #{variant_id})")
      end
    end

    for item in INTERVENTIONS
      replace_items_in_array(item[:table], item[:column], item)
    end
  end

  def down
    for item in INTERVENTIONS
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end

    for item in PRODUCT_READING_ITEMS
      if variant_id = connection.select_value("SELECT min(id) FROM product_nature_variants WHERE reference_name = '#{item[:reference_name]}'").to_i
        execute("UPDATE #{item[:table]} SET #{item[:column]} = '#{item[:old_value]}' WHERE #{item[:column]} = '#{item[:new_value]}' AND product_id IN (SELECT id FROM products WHERE variant_id = #{variant_id})")
      end
    end

    for item in PRODUCT_NATURE_VARIANT_READING_ITEMS
      next unless variant_id = connection.select_value("SELECT min(id) FROM product_nature_variants WHERE reference_name = '#{item[:reference_name]}'").to_i
      if item[:old_frozen_indicator_name] && item[:new_frozen_indicator_name]
        fail NotImplemented
      elsif item[:new_frozen_indicator_name]
        execute("DELETE FROM #{item[:table]} WHERE variant_id = '#{variant_id}' AND indicator_name = '#{item[:new_frozen_indicator_name]}'")
      elsif item[:new_value] && item[:old_value]
        execute("UPDATE #{item[:table]} SET #{item[:column]} = '#{item[:old_value]}' WHERE #{item[:column]} = '#{item[:new_value]}' AND variant_id = #{variant_id}")
      end
    end

    for item in PRODUCT_NATURE_VARIANT_ITEMS
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end
  end
end
