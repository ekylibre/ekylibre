class UpdateProductNaturesNomen < ActiveRecord::Migration
  
  # for product_natures
  product_natures = []
  product_natures << {item: 'complete_sower', old_abilities: 'sow, spray, spread(mineral_matter)', new_abilities: 'sow, spray, spread(preparation)'}
  product_natures << {item: 'spreader', old_abilities: 'spread(mineral_matter)', new_abilities: 'spread(preparation)'}
  
  def up
    for product_nature in product_natures
      execute "UPDATE product_natures SET abilities = #{product_nature.new_abilities} WHERE reference_name = #{product_nature.item} AND abilities = #{product_nature.old_abilities}"
    end
  end
  
  def down
    for product_nature in product_natures
      execute "UPDATE product_natures SET abilities = #{product_nature.old_abilities} WHERE reference_name = #{product_nature.item} AND abilities = #{product_nature.new_abilities}"
    end

  end
end
