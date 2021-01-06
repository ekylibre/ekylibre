class RemoveVitisChildInNomenclatures < ActiveRecord::Migration[4.2]
  def up
    # remove all vitis_xxx and keep only vitis in variety
    # replace all vitis_xxx by vitis in records
    execute <<-SQL
      UPDATE activities
      SET cultivation_variety = 'vitis'
      WHERE cultivation_variety LIKE 'vitis%'
    SQL

    execute <<-SQL
      UPDATE product_nature_variants
      SET variety = 'vitis'
      WHERE variety LIKE 'vitis%'
    SQL

    execute <<-SQL
      UPDATE product_nature_variants
      SET derivative_of = 'vitis'
      WHERE derivative_of LIKE 'vitis%'
    SQL

    execute <<-SQL
      UPDATE product_natures
      SET variety = 'vitis'
      WHERE variety LIKE 'vitis%'
    SQL

    execute <<-SQL
      UPDATE product_natures
      SET derivative_of = 'vitis'
      WHERE derivative_of LIKE 'vitis%'
    SQL

    execute <<-SQL
      UPDATE products
      SET variety = 'vitis'
      WHERE variety LIKE 'vitis%'
    SQL

    execute <<-SQL
      UPDATE products
      SET derivative_of = 'vitis'
      WHERE derivative_of LIKE 'vitis%'
    SQL
  end

  def down
    # NOOP
  end
end
