class UpdateConditionningUnit < ActiveRecord::Migration[5.0]

  def up
    # update conditionning_unit when it 1000kg_big_bag to ton_bulk
    execute <<-SQL
      UPDATE products SET conditioning_unit_id = (SELECT min(id) FROM units where reference_name = 'ton_bulk')
        WHERE conditioning_unit_id = (SELECT min(id) FROM units WHERE reference_name = '1000kg_big_bag')
        AND variety <> 'seed'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE products SET conditioning_unit_id = (SELECT min(id) FROM units where reference_name = '1000kg_big_bag')
        WHERE conditioning_unit_id = (SELECT min(id) FROM units WHERE reference_name = 'ton_bulk')
        AND variety <> 'seed'
    SQL
  end
end
