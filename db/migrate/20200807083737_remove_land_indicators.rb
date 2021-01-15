class RemoveLandIndicators < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        # remove land indicators
        execute <<-SQL
          DELETE FROM product_nature_variant_readings
          WHERE indicator_name = 'land'
        SQL

        execute <<-SQL
          DELETE FROM  product_readings
          WHERE indicator_name = 'land'
        SQL
      end
    end
  end
end
