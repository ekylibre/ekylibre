class UpdateProductNaturesNomen < ActiveRecord::Migration
  
  # TODO need to be refactorized by a more powerfull system
  ABILITIES = {
    'complete_sower' => {old: 'sow, spray, spread(mineral_matter)', new: 'sow, spray, spread(preparation)'},
    'spreader' => {old: 'spread(mineral_matter)', new: 'spread(preparation)'}
  }
  
  def up
    # check if product_nature is present in DB and update it with new abilities
    for product_nature, abilities in ABILITIES       
      if connection.select_value("SELECT count(*) FROM product_natures WHERE reference_name = '#{product_nature}'").to_i > 0
        say "update " + product_nature.inspect.yellow + " with " + abilities[:new].inspect.green
        execute "UPDATE product_natures SET abilities_list = '#{abilities[:new]}' WHERE reference_name = '#{product_nature}' AND abilities_list = '#{abilities[:old]}'"
      end
    end
    
    # add column for maximum_nitrogen_input in mmp
    add_column :manure_management_plan_zones, :maximum_nitrogen_input, :decimal, precision: 19, scale: 4    
  end
  
  def down
    # remove column for maximum_nitrogen_input in mmp
    remove_column :manure_management_plan_zones, :maximum_nitrogen_input

    # check if product_nature is present in DB and update it with old abilities
    for product_nature, abilities in ABILITIES.reverse
      if connection.select_value("SELECT count(*) FROM product_natures WHERE reference_name = '#{product_nature}'").to_i > 0
        say "restore " + product_nature.inspect.yellow + " with " + abilities[:old].inspect.red
        execute "UPDATE product_natures SET abilities_list = '#{abilities[:old]}' WHERE reference_name = '#{product_nature}' AND abilities_list = '#{abilities[:new]}'"
      end
    end  
  end

end
