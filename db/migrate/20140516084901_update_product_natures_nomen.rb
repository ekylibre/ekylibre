class UpdateProductNaturesNomen < ActiveRecord::Migration
  

  def replace_items_in_array(table, column, options = {})
    
    conditions = '1=1'
    if options[:reference_name]
      conditions = "reference_name = '#{options[:reference_name]}'"
    end
    
    # ex of column = abilities_list
    say "replace item in array #{table}##{column}  #{options.inspect}"
    
    if options[:old] and options[:new]
      execute("UPDATE #{table} SET #{column} = REPLACE(#{column}, '#{options[:old]}', '#{options[:new]}') WHERE #{column} LIKE '%#{options[:old]}%' AND #{conditions}")
    elsif options[:new]
      execute("UPDATE #{table} SET #{column} = COALESCE(NULLIF(#{column},'') || ', #{options[:new]}',  '#{options[:new]}') WHERE #{conditions}")
    elsif options[:old]
      execute("UPDATE #{table} SET #{column} =REPLACE(REPLACE(REPLACE(#{column}, ', #{options[:old]}', ''), '#{options[:old]}', ''),'#{options[:old]},', '') WHERE #{conditions}")
    else
      raise StandardException 
    end
    
  end

  ITEMS = [
       {table: 'product_natures', column: 'abilities_list', old: 'spread(mineral_matter)', new: 'spread(preparation)'},
       {table: 'product_natures', column: 'abilities_list', old: 'spread(organic_matter)', new: 'spread(excrement)'},
       {table: 'product_natures', column: 'abilities_list', old: 'store(organic_matter)', new: 'store(excrement)'},
       
       {table: 'product_natures', column: 'variable_indicators_list', old: 'plants_density', new: 'plants_count'},
       
       {table: 'product_natures', column: 'frozen_indicators_list', old: 'sulfur_dioxyde_concentration', new: 'sulfur_dioxide_concentration'},
       
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'herbicide'},
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'fungicide'},
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'additive'},
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'insecticide'},
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'molluscicide'},
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'chemical_fertilizer'},
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'animal_medicine'},
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'disinfectant'},
       {table: 'product_natures', column: 'variety', new: 'equipment', old: 'bottling'},
       
       {table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'grain_crop'},
       {table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'crop'},
       {table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'cereal_crop'},
       
       {table: 'product_natures', column: 'variable_indicators_list', new: 'rows_interval', reference_name: 'fruit_crop'},
       {table: 'product_natures', column: 'variable_indicators_list', new: 'plants_interval', reference_name: 'fruit_crop'},
       {table: 'product_natures', column: 'variable_indicators_list', old: 'net_surface_area', reference_name: 'fruit_crop'},
       {table: 'product_natures', column: 'frozen_indicators_list', new: 'net_surface_area', reference_name: 'fruit_crop'},
       
       {table: 'product_natures', column: 'variable_indicators_list', new: 'rows_interval', reference_name: 'walnut_crop'},
       {table: 'product_natures', column: 'variable_indicators_list', new: 'plants_interval', reference_name: 'walnut_crop'},
       {table: 'product_natures', column: 'variable_indicators_list', old: 'net_surface_area', reference_name: 'walnut_crop'},
       {table: 'product_natures', column: 'frozen_indicators_list', new: 'net_surface_area', reference_name: 'walnut_crop'},
       
       {table: 'product_natures', column: 'variable_indicators_list', new: 'rows_interval', reference_name: 'wine_crop'},
       {table: 'product_natures', column: 'variable_indicators_list', new: 'plants_interval', reference_name: 'wine_crop'},
       {table: 'product_natures', column: 'frozen_indicators_list', new: 'net_surface_area', reference_name: 'wine_crop'},
       
       {table: 'product_natures', column: 'derivative_of', new: 'plant', old: 'poaceae', reference_name: 'grass'},
       
       {table: 'product_natures', column: 'variety', new: 'preparation', old: 'matter', reference_name: 'clarification_solution'},
       
       {table: 'product_natures', column: 'abilities_list', old: 'kill(bacteria virus fungus)', new: 'kill(bacteria)', reference_name: 'animal_medicine'},
       {table: 'product_natures', column: 'abilities_list',  new: 'kill(virus)', reference_name: 'animal_medicine'},
       {table: 'product_natures', column: 'abilities_list',  new: 'kill(fungus)', reference_name: 'animal_medicine'},
       {table: 'product_natures', column: 'abilities_list',  new: 'kill(fungus)', reference_name: 'animal_medicine'},
        
       {table: 'product_natures', column: 'variable_indicators_list',  new: 'nitrogen_concentration', reference_name: 'running_water'},
       {table: 'product_natures', column: 'variable_indicators_list',  new: 'potential_hydrogen', reference_name: 'running_water'},
       
        {table: 'product_natures', column: 'variable_indicators_list',  new: 'nitrogen_concentration', reference_name: 'irrigation_water'},
       {table: 'product_natures', column: 'variable_indicators_list',  new: 'potential_hydrogen', reference_name: 'irrigation_water'},
       
       {table: 'product_natures', column: 'variable_indicators_list',  new: 'nitrogen_concentration', reference_name: 'natural_water'},
       {table: 'product_natures', column: 'variable_indicators_list',  new: 'potential_hydrogen', reference_name: 'natural_water'}
  ]
  
   CHANGING_CATEGORIES = [
       {table: 'product_natures', column: 'category_id', linked_table: 'product_nature_categories', reference_name: 'animal_food_building_division', new_linked_reference_name: 'building_division', old_linked_reference_name: 'equipment'},
       {table: 'product_natures', column: 'category_id', linked_table: 'product_nature_categories', reference_name: 'silage_division', new_linked_reference_name: 'building_division', old_linked_reference_name: 'equipment'}
     ]

  def up
    # check if product_nature is present in DB and update it with new values
    for item in ITEMS       
      replace_items_in_array(item[:table], item[:column], item)
    end
    
    
    for item in CHANGING_CATEGORIES
      if connection.select_value("SELECT count(*) FROM #{item[:linked_table]} WHERE reference_name = '#{item[:new_linked_reference_name]}'").to_i > 0
        execute("UPDATE #{item[:table]} SET #{item[:column]} = (SELECT min(id) FROM #{item[:linked_table]} WHERE reference_name = '#{item[:new_linked_reference_name]}')")
      end
    end
    
    
    # add column for maximum_nitrogen_input in mmp
    add_column :manure_management_plan_zones, :maximum_nitrogen_input, :decimal, precision: 19, scale: 4    
  end
  
  def down
    # remove column for maximum_nitrogen_input in mmp
    remove_column :manure_management_plan_zones, :maximum_nitrogen_input
    
    for item in CHANGING_CATEGORIES
      if connection.select_value("SELECT count(*) FROM #{item[:linked_table]} WHERE reference_name = '#{item[:old_linked_reference_name]}'").to_i > 0
        execute("UPDATE #{item[:table]} SET #{item[:column]} = (SELECT min(id) FROM #{item[:linked_table]} WHERE reference_name = '#{item[:old_linked_reference_name]}')")
      end
    end
    
    # check if product_nature is present in DB and update it with old abilities
# check if product_nature is present in DB and update it with new abilities

    for item in ITEMS       
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end  
  end

end
