class ChangeProcedures < ActiveRecord::Migration
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
      raise StandardException
    end
  end

  PRODUCT_NATURE_ITEMS = [

    { table: 'product_natures', column: 'variable_indicators_list', new: 'wait_before_harvest_period', reference_name: 'herbicide' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'approved_input_dose', reference_name: 'herbicide' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'untreated_zone_length', reference_name: 'herbicide' },

    { table: 'product_natures', column: 'variable_indicators_list', new: 'wait_before_harvest_period', reference_name: 'fungicide' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'approved_input_dose', reference_name: 'fungicide' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'untreated_zone_length', reference_name: 'fungicide' },

    { table: 'product_natures', column: 'variable_indicators_list', new: 'wait_before_harvest_period', reference_name: 'insecticide' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'approved_input_dose', reference_name: 'insecticide' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'untreated_zone_length', reference_name: 'insecticide' },

    { table: 'product_natures', column: 'variable_indicators_list', new: 'wait_before_harvest_period', reference_name: 'molluscicide' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'approved_input_dose', reference_name: 'molluscicide' },
    { table: 'product_natures', column: 'variable_indicators_list', new: 'untreated_zone_length', reference_name: 'molluscicide' }

  ].freeze

  CHANGING_INTERVENTION_CAST_REFERENCE_NAMES = [

    { procedure_reference_name: 'base-animal_treatment-0', column: 'reference_name', new: 'animal_medicine', old: 'medicine' },
    { procedure_reference_name: 'base-animal_treatment-0', column: 'reference_name', new: 'animal_medicine_to_give', old: 'medicine_to_give' },
    { procedure_reference_name: 'base-spraying_on_cultivation-0', column: 'reference_name', new: 'plant_medicine', old: 'medicine' },
    { procedure_reference_name: 'base-spraying_on_cultivation-0', column: 'reference_name', new: 'plant_medicine_to_spray', old: 'medicine_to_spray' }
  ].freeze

  CHANGING_INTERVENTION_CAST_ROLES = [

    { procedure_reference_name: 'base-plowing-0', column: 'roles', new: 'plowing-tool', old: '', reference_name: 'tractor' },
    { procedure_reference_name: 'base-plowing-0', column: 'roles', new: 'plowing-tool', old: '', reference_name: 'plow' },
    { procedure_reference_name: 'base-hoeing-0', column: 'roles', new: 'raking-tool', old: '', reference_name: 'tractor' },
    { procedure_reference_name: 'base-hoeing-0', column: 'roles', new: 'raking-tool', old: '', reference_name: 'cultivator' },
    { procedure_reference_name: 'base-raking-0', column: 'roles', new: 'raking-tool', old: '', reference_name: 'tractor' },
    { procedure_reference_name: 'base-raking-0', column: 'roles', new: 'raking-tool', old: '', reference_name: 'harrow' },
    { procedure_reference_name: 'base-superficial_plowing-0', column: 'roles', new: 'raking-tool', old: '', reference_name: 'tractor' },
    { procedure_reference_name: 'base-superficial_plowing-0', column: 'roles', new: 'raking-tool', old: '', reference_name: 'plow' },
    { procedure_reference_name: 'base-uncompacting-0', column: 'roles', new: 'plowing-tool', old: '', reference_name: 'tractor' },
    { procedure_reference_name: 'base-uncompacting-0', column: 'roles', new: 'plowing-tool', old: '', reference_name: 'harrow' },
    { procedure_reference_name: 'base-implanting-0', column: 'roles', new: 'implanting-tool', old: 'implant-tool', reference_name: 'implanter_tool' },
    { procedure_reference_name: 'base-implanting-0', column: 'roles', new: 'implanting-doer', old: 'implant-doer', reference_name: 'implanter_man' },
    { procedure_reference_name: 'base-implanting-0', column: 'roles', new: 'implanting-tool', old: 'implant-tool', reference_name: 'tractor' },
    { procedure_reference_name: 'base-implanting-0', column: 'roles', new: 'implanting-target', old: 'implant-target', reference_name: 'land_parcel' },
    { procedure_reference_name: 'base-implanting-0', column: 'roles', new: 'implanting-input', old: 'implant-input', reference_name: 'plants_to_fix' },
    { procedure_reference_name: 'base-implanting-0', column: 'roles', new: 'implanting-output', old: 'implant-output', reference_name: 'cultivation' }

  ].freeze

  INTERVENTION_CAST_ITEMS = [

    { table: 'intervention_casts', column: 'roles', new: 'sowing-input_origin', reference_name: 'seeds' },
    { table: 'intervention_casts', column: 'roles', new: 'implanting-input_origin', reference_name: 'plants' },

    { table: 'intervention_casts', column: 'roles', new: 'animal_curative_medicine_admission-input_origin', reference_name: 'animal_medicine' },

    { table: 'intervention_casts', column: 'roles', new: 'plant_illness_treatment-input_origin', reference_name: 'plant_medicine' },

    { table: 'intervention_casts', column: 'roles', new: 'plant_illness_treatment-input_origin', reference_name: 'insecticide' },
    { table: 'intervention_casts', column: 'roles', new: 'plant_illness_treatment-input_origin', reference_name: 'molluscicide' }
  ].freeze

  def up
    add_column :interventions, :description, :text

    for item in PRODUCT_NATURE_ITEMS
      replace_items_in_array(item[:table], item[:column], item)
    end

    # change roles
    for item in CHANGING_INTERVENTION_CAST_REFERENCE_NAMES
      execute("UPDATE intervention_casts SET reference_name = '#{item[:new]}' WHERE reference_name = '#{item[:old]}' AND intervention_id IN (SELECT i.id FROM interventions i WHERE i.reference_name = '#{item[:procedure_reference_name]}')")
    end

    for item in CHANGING_INTERVENTION_CAST_ROLES
      execute("UPDATE intervention_casts SET #{item[:column]} = '#{item[:new]}' WHERE #{item[:column]} = '#{item[:old]}' AND reference_name = '#{item[:reference_name]}' AND intervention_id IN (SELECT i.id FROM interventions i WHERE i.reference_name = '#{item[:procedure_reference_name]}')")
    end

    # check if product_nature is present in DB and update it with new values
    for item in INTERVENTION_CAST_ITEMS
      replace_items_in_array(item[:table], item[:column], item)
    end
  end

  def down
    for item in INTERVENTION_CAST_ITEMS
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end

    for item in CHANGING_INTERVENTION_CAST_ROLES
      execute("UPDATE intervention_casts SET #{item[:column]} = '#{item[:old]}' WHERE #{item[:column]} = '#{item[:new]}' AND reference_name = '#{item[:reference_name]}' AND intervention_id IN (SELECT i.id FROM interventions i WHERE i.reference_name = '#{item[:procedure_reference_name]}')")
    end

    # change roles name in medicine casts
    for item in CHANGING_INTERVENTION_CAST_REFERENCE_NAMES
      execute("UPDATE intervention_casts SET reference_name = '#{item[:old]}' WHERE reference_name = '#{item[:new]}' AND intervention_id IN (SELECT i.id FROM interventions i WHERE i.reference_name = '#{item[:procedure_reference_name]}')")
    end

    for item in PRODUCT_NATURE_ITEMS
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end

    remove_column :interventions, :description
  end
end
