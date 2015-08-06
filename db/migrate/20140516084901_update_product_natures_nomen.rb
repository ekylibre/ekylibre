class UpdateProductNaturesNomen < ActiveRecord::Migration
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

  PRODUCT_NATURE_ITEMS = [
    { table: 'product_natures', column: 'abilities_list', old: 'spread(mineral_matter)', new: 'spread(preparation)' },
    { table: 'product_natures', column: 'abilities_list', old: 'spread(organic_matter)', new: 'spread(excrement)' },
    { table: 'product_natures', column: 'abilities_list', old: 'store(organic_matter)', new: 'store(excrement)' },

    { table: 'product_natures', column: 'variable_indicators_list', old: 'plants_density', new: 'plants_count' },

    { table: 'product_natures', column: 'frozen_indicators_list', old: 'sulfur_dioxyde_concentration', new: 'sulfur_dioxide_concentration' },

    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'herbicide' },
    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'fungicide' },
    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'additive' },
    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'insecticide' },
    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'molluscicide' },
    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'chemical_fertilizer' },
    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'animal_medicine' },
    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'disinfectant' },
    { table: 'product_natures', column: 'variety', new: 'equipment', old: 'bottling' },

    { table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'grain_crop' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'crop' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'cereal_crop' },

    { table: 'product_natures', column: 'variable_indicators_list', new: 'rows_interval', reference_name: 'fruit_crop' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'plants_interval', reference_name: 'fruit_crop' },
    { table: 'product_natures', column: 'variable_indicators_list', old: 'net_surface_area', reference_name: 'fruit_crop' },
    { table: 'product_natures', column: 'frozen_indicators_list', new: 'net_surface_area', reference_name: 'fruit_crop' },

    { table: 'product_natures', column: 'variable_indicators_list', new: 'rows_interval', reference_name: 'walnut_crop' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'plants_interval', reference_name: 'walnut_crop' },
    { table: 'product_natures', column: 'variable_indicators_list', old: 'net_surface_area', reference_name: 'walnut_crop' },
    { table: 'product_natures', column: 'frozen_indicators_list', new: 'net_surface_area', reference_name: 'walnut_crop' },

    { table: 'product_natures', column: 'variable_indicators_list', new: 'rows_interval', reference_name: 'wine_crop' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'plants_interval', reference_name: 'wine_crop' },
    { table: 'product_natures', column: 'frozen_indicators_list', new: 'net_surface_area', reference_name: 'wine_crop' },

    { table: 'product_natures', column: 'derivative_of', new: 'plant', old: 'poaceae', reference_name: 'grass' },

    { table: 'product_natures', column: 'variety', new: 'preparation', old: 'matter', reference_name: 'clarification_solution' },

    { table: 'product_natures', column: 'abilities_list', old: 'kill(bacteria virus fungus)', new: 'kill(bacteria)', reference_name: 'animal_medicine' },
    { table: 'product_natures', column: 'abilities_list',  new: 'kill(virus)', reference_name: 'animal_medicine' },
    { table: 'product_natures', column: 'abilities_list',  new: 'kill(fungus)', reference_name: 'animal_medicine' },

    { table: 'product_natures', column: 'abilities_list',  old: 'kill(plant)', new: 'kill(plant), care(plant)', reference_name: 'herbicide' },
    { table: 'product_natures', column: 'abilities_list',  old: 'kill(fungus)', new: 'kill(fungus), care(plant)', reference_name: 'fungicide' },
    { table: 'product_natures', column: 'abilities_list',  old: 'kill(insecta)', new: 'kill(insecta), care(plant)', reference_name: 'insecticide' },
    { table: 'product_natures', column: 'abilities_list',  old: 'kill(mollusca)', new: 'kill(mollusca), care(plant)', reference_name: 'molluscicide' },

    { table: 'product_natures', column: 'variable_indicators_list',  new: 'nitrogen_concentration', reference_name: 'running_water' },
    { table: 'product_natures', column: 'variable_indicators_list',  new: 'potential_hydrogen', reference_name: 'running_water' },

    { table: 'product_natures', column: 'variable_indicators_list',  new: 'nitrogen_concentration', reference_name: 'irrigation_water' },
    { table: 'product_natures', column: 'variable_indicators_list',  new: 'potential_hydrogen', reference_name: 'irrigation_water' },

    { table: 'product_natures', column: 'variable_indicators_list',  new: 'nitrogen_concentration', reference_name: 'natural_water' },
    { table: 'product_natures', column: 'variable_indicators_list',  new: 'potential_hydrogen', reference_name: 'natural_water' }
  ]

  CHANGING_CATEGORIES = [
    { table: 'product_natures', column: 'category_id', linked_table: 'product_nature_categories', reference_name: 'animal_food_building_division', new_linked_reference_name: 'building_division', old_linked_reference_name: 'equipment' },
    { table: 'product_natures', column: 'category_id', linked_table: 'product_nature_categories', reference_name: 'silage_division', new_linked_reference_name: 'building_division', old_linked_reference_name: 'equipment' }
  ]

  PRODUCT_NATURE_VARIANT_ITEMS = [
    { table: 'product_nature_variants', column: 'reference_name', old: 'alfalfa_crop', new: 'lucerne_crop' },
    { table: 'product_nature_variants', column: 'derivative_of', old: 'organic_matter', new: 'raw_matter', reference_name: 'wine_vinasse' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:ammonitre_33,5%_vr', new: 'coop:ammonitre_33,5__vr' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:super_46%_gr._vr', new: 'coop:super_46__gr__vr' },
    { table: 'product_nature_variants', column: 'reference_name', old: 'coop:chlorure_60%_gr_vr', new: 'coop:chlorure_60__gr_vr' },
    { table: 'product_nature_variants', column: 'unit_name', old: 'bag', new: '20kg_bag', reference_name: 'coop:metarex_rg_tds_20kg' }
  ]

  PRODUCT_NATURE_VARIANT_READING_ITEMS = [
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'lucerne_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'apple_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'walnut_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'hazel_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'rose_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'raspberry_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'strawberry_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'gooseberry_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'blackcurrant_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'pear_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'peach_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'fig_crop' },
    { table: 'product_nature_variant_readings', new_frozen_indicator_name: 'net_surface_area', new_frozen_indicator_datatype: 'measure', new_value: '1.00', new_unit: 'hectare', new_absolute_value: '10000.00', new_absolute_unit: 'square_meter', reference_name: 'vine_grape_crop' }

  ]
  # INDICATOR_NAME_CHANGES = {
  #   sulfur_dioxyde_concentration: :sulfur_dioxide_concentration,
  #   plants_density: :plants_count
  # }
  # INDICATOR_TABLES = [:product_readings, :product_nature_variant_readings, :production_support_markers, :analysis_items]

  INDICATOR_ITEMS = [
    # for sulfur_dioxide_concentration
    { table: 'product_readings', column: 'indicator_name', old: 'sulfur_dioxyde_concentration', new: 'sulfur_dioxide_concentration' },
    { table: 'product_nature_variant_readings', column: 'indicator_name', new: 'sulfur_dioxide_concentration', old: 'sulfur_dioxyde_concentration' },
    { table: 'production_support_markers', column: 'indicator_name', new: 'sulfur_dioxide_concentration', old: 'sulfur_dioxyde_concentration' },
    { table: 'analysis_items', column: 'indicator_name', new: 'sulfur_dioxide_concentration', old: 'sulfur_dioxyde_concentration' },

    # for plants_count
    { table: 'product_readings', column: 'indicator_name', old: 'plants_density', new: 'plants_count' },
    { table: 'product_nature_variant_readings', column: 'indicator_name', new: 'plants_count', old: 'plants_density' },
    { table: 'production_support_markers', column: 'indicator_name', new: 'plants_count', old: 'plants_density' },
    { table: 'analysis_items', column: 'indicator_name', new: 'plants_count', old: 'plants_density' }

  ]

  def up
    # check if product_nature is present in DB and update it with new values
    for item in PRODUCT_NATURE_ITEMS
      replace_items_in_array(item[:table], item[:column], item)
    end

    for item in CHANGING_CATEGORIES
      if connection.select_value("SELECT count(*) FROM #{item[:linked_table]} WHERE reference_name = '#{item[:new_linked_reference_name]}'").to_i > 0
        execute("UPDATE #{item[:table]} SET #{item[:column]} = (SELECT min(id) FROM #{item[:linked_table]} WHERE reference_name = '#{item[:new_linked_reference_name]}')")
      end
    end

    for item in PRODUCT_NATURE_VARIANT_ITEMS
      replace_items_in_array(item[:table], item[:column], item)
    end

    for item in PRODUCT_NATURE_VARIANT_READING_ITEMS
      if variant_id = connection.select_value("SELECT min(id) FROM product_nature_variants WHERE reference_name = '#{item[:reference_name]}'").to_i
        if item[:old_frozen_indicator_name] && item[:new_frozen_indicator_name]
          fail NotImplemented
        elsif item[:new_frozen_indicator_name]
          if item[:new_frozen_indicator_datatype] == 'measure'
            execute("INSERT INTO #{item[:table]} (variant_id, indicator_name, indicator_datatype, measure_value_value, measure_value_unit, absolute_measure_value_value, absolute_measure_value_unit, created_at, updated_at) VALUES ('#{variant_id}', '#{item[:new_frozen_indicator_name]}', '#{item[:new_frozen_indicator_datatype]}', '#{item[:new_value]}', '#{item[:new_unit]}', '#{item[:new_absolute_value]}', '#{item[:new_absolute_unit]}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
          end
        elsif item[:new_value] && item[:old_value]
          execute("UPDATE #{item[:table]} SET #{item[:column]} = '#{item[:new_value]}' WHERE #{item[:column]} = '#{item[:old_value]}'")
        end
      end
    end

    for item in INDICATOR_ITEMS
      replace_items_in_array(item[:table], item[:column], item)
    end

    ################ END FOR NOMENCLATURES UPDATE ######################

    # add column for maximum_nitrogen_input in mmp
    add_column :manure_management_plan_zones, :maximum_nitrogen_input, :decimal, precision: 19, scale: 4
    # add column for picking roles into nomenclatures
    add_column :roles, :reference_name, :string
  end

  def down
    # remove column for maximum_nitrogen_input in mmp
    remove_column :manure_management_plan_zones, :maximum_nitrogen_input
    remove_column :roles, :reference_name

    for item in INDICATOR_ITEMS
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end

    for item in PRODUCT_NATURE_VARIANT_READING_ITEMS
      if variant_id = connection.select_value("SELECT min(id) FROM product_nature_variants WHERE reference_name = '#{item[:reference_name]}'").to_i
        if item[:old_frozen_indicator_name] && item[:new_frozen_indicator_name]
          fail NotImplemented
        elsif item[:new_frozen_indicator_name]
          execute("DELETE FROM #{item[:table]} WHERE variant_id = '#{variant_id}' AND indicator_name = '#{item[:new_frozen_indicator_name]}'")
        elsif item[:new_value] && item[:old_value]
          execute("UPDATE #{item[:table]} SET #{item[:column]} = '#{item[:old_value]}' WHERE #{item[:column]} = '#{item[:new_value]}'")
        end
      end
    end

    for item in PRODUCT_NATURE_VARIANT_ITEMS
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end

    for item in CHANGING_CATEGORIES
      if connection.select_value("SELECT count(*) FROM #{item[:linked_table]} WHERE reference_name = '#{item[:old_linked_reference_name]}'").to_i > 0
        execute("UPDATE #{item[:table]} SET #{item[:column]} = (SELECT min(id) FROM #{item[:linked_table]} WHERE reference_name = '#{item[:old_linked_reference_name]}')")
      end
    end

    # check if product_nature is present in DB and update it with old abilities
    # check if product_nature is present in DB and update it with new abilities

    for item in PRODUCT_NATURE_ITEMS
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end
  end
end
