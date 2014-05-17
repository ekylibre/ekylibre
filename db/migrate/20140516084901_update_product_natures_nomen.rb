class UpdateProductNaturesNomen < ActiveRecord::Migration
  
  # TODO need to be refactorized by a more powerfull system
  
  
  def up
    # for product_natures
    product_natures = []
    product_natures << {item: 'complete_sower', old_abilities: 'sow, spray, spread(mineral_matter)', new_abilities: 'sow, spray, spread(preparation)'}
    product_natures << {item: 'spreader', old_abilities: 'spread(mineral_matter)', new_abilities: 'spread(preparation)'}
    # check if product_nature is present in DB and update it with new abilities
    for product_nature in product_natures       
      if connection.select_value("SELECT count(*) FROM product_natures WHERE reference_name = '#{product_nature[:item]}'").to_i > 0
        say "update " + product_nature[:item].inspect.yellow + " with " + product_nature[:new_abilities].inspect.green
        execute "UPDATE product_natures SET abilities_list = '#{product_nature[:new_abilities]}' WHERE reference_name = '#{product_nature[:item]}' AND abilities_list = '#{product_nature[:old_abilities]}'"
      end
    end
  end
  
  def down
    product_natures = []
    product_natures << {item: 'complete_sower', old_abilities: 'sow, spray, spread(mineral_matter)', new_abilities: 'sow, spray, spread(preparation)'}
    product_natures << {item: 'spreader', old_abilities: 'spread(mineral_matter)', new_abilities: 'spread(preparation)'}
    # check if product_nature is present in DB and update it with old abilities
    for product_nature in product_natures       
      if connection.select_value("SELECT count(*) FROM product_natures WHERE reference_name = '#{product_nature[:item]}'").to_i > 0
        say "restore " + product_nature[:item].inspect.yellow + " with " + product_nature[:old_abilities].inspect.red
        execute "UPDATE product_natures SET abilities_list = '#{product_nature[:old_abilities]}' WHERE reference_name = '#{product_nature[:item]}' AND abilities_list = '#{product_nature[:new_abilities]}'"
      end
    end

  end
end
