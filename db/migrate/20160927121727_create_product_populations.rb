class CreateProductPopulations < ActiveRecord::Migration
  def change
    create_table :product_populations do |t|
      t.references :product, index: true, foreign_key: true
      t.decimal :value, precision: 19, scale: 4

      t.datetime :started_at, null: false
      t.datetime :stopped_at

      t.stamps

      t.index :started_at
      t.index :stopped_at
      t.index [:product_id, :started_at], unique: true
    end

    reversible do |dir|
      dir.up do
        # Compute the various populations.
        execute <<-SQL
          INSERT INTO product_populations (product_id, started_at, value, created_at, updated_at, lock_version)
          SELECT movements.product_id, movements.started_at, SUM(precedings.delta), now(), now(), 1
            FROM product_movements as movements
            JOIN product_movements as precedings
            ON movements.started_at >= precedings.started_at AND movements.product_id = precedings.product_id
            GROUP BY movements.product_id, movements.started_at
            ORDER BY movements.started_at
        SQL

        # Compute the stopped_at of the populations.
        execute <<-SQL
          UPDATE product_populations
          SET stopped_at = matches.next_started_at
          FROM (
            SELECT
              pp.started_at,
              pp.product_id,
              LEAD(pp.product_id) OVER (ORDER BY pp.product_id, pp.started_at) AS next_product_id,
              LEAD(pp.started_at) OVER (ORDER BY pp.product_id, pp.started_at) AS next_started_at
            FROM product_populations pp
            ORDER BY pp.product_id, pp.started_at
          ) matches
          WHERE product_populations.product_id = matches.product_id
            AND product_populations.started_at = matches.started_at
            AND matches.product_id = matches.next_product_id
        SQL
      end

      # No need for a dir.down since it's pure data and that the table
      # is already destroyed with all of its data.
    end
  end
end
