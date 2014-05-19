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
      {table: 'product_natures', column: 'variable_indicators_list', old: 'plants_density', new: 'plants_count'},
      {table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'grain_crop'},
       {table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'crop'},
       {table: 'product_natures', column: 'variable_indicators_list', new: 'fresh_mass', reference_name: 'cereal_crop'}
  ]

  def up
    # check if product_nature is present in DB and update it with new abilities
    for item in ITEMS       
      replace_items_in_array(item[:table], item[:column], item)
    end
    
    # add column for maximum_nitrogen_input in mmp
    add_column :manure_management_plan_zones, :maximum_nitrogen_input, :decimal, precision: 19, scale: 4    
  end
  
  def down
    # remove column for maximum_nitrogen_input in mmp
    remove_column :manure_management_plan_zones, :maximum_nitrogen_input

    # check if product_nature is present in DB and update it with old abilities
# check if product_nature is present in DB and update it with new abilities

    for item in ITEMS       
      replace_items_in_array(item[:table], item[:column], new: item[:old], old: item[:new])
    end  
  end

end
