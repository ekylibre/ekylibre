class CreateProductPopulations < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE VIEW product_populations AS
      SELECT DISTINCT ON (movements.started_at, movements.product_id)
          movements.product_id AS product_id,
          movements.started_at AS started_at,
          SUM(precedings.delta) AS value,
          MAX(movements.creator_id) AS creator_id,
          MAX(movements.created_at) AS created_at,
          MAX(movements.updated_at) AS updated_at,
          MAX(movements.updater_id) AS updater_id,
          MIN(movements.id) AS id,
          1 AS lock_version

          FROM product_movements as movements
          LEFT JOIN (SELECT SUM(delta) AS delta, product_id, started_at FROM product_movements GROUP BY product_id, started_at) as precedings
          ON movements.started_at >= precedings.started_at AND movements.product_id = precedings.product_id
          GROUP BY movements.id
    SQL
    execute 'CREATE RULE delete_product_populations AS ON DELETE TO product_populations DO INSTEAD NOTHING;'
  end

  def down
    execute <<-SQL
      DROP VIEW product_populations
    SQL
  end
end
