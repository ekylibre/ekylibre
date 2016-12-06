class UpdateProductPopulationToHandleMergings < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE OR REPLACE VIEW population_movements AS
      SELECT product_id, started_at, delta, creator_id, created_at, updater_id, updated_at, id, lock_version
      FROM product_movements
      UNION ALL
        SELECT
          destinations.id           AS product_id,
          merges.merged_at          AS started_at,
          SUM(movements.delta)     AS delta,
          merges.creator_id         AS creator_id,
          merges.created_at         AS created_at,
          merges.updater_id         AS updater_id,
          merges.updated_at         AS updated_at,
          MIN(movements.id)         AS id,
          1                         AS lock_version
        FROM products               AS destinations
        LEFT JOIN product_mergings  AS merges
               ON merges.merged_with_id = destinations.id
        LEFT JOIN products          AS sources
               ON merges.product_id     = sources.id
        LEFT JOIN product_movements AS movements
               ON movements.product_id  = sources.id
                  AND movements.started_at <= merges.merged_at
        GROUP BY 1, 2, 4, 5, 6, 7
      UNION ALL
        SELECT
          sources.id                AS product_id,
          merges.merged_at          AS started_at,
          -SUM(movements.delta)    AS delta,
          merges.creator_id         AS creator_id,
          merges.created_at         AS created_at,
          merges.updater_id         AS updater_id,
          merges.updated_at         AS updated_at,
          MAX(movements.id)         AS id,
          1                         AS lock_version
        FROM products               AS destinations
        LEFT JOIN product_mergings  AS merges
               ON merges.merged_with_id = destinations.id
        LEFT JOIN products          AS sources
               ON merges.product_id     = sources.id
        LEFT JOIN product_movements AS movements
               ON movements.product_id  = sources.id
                  AND movements.started_at <= merges.merged_at
        GROUP BY 1, 2, 4, 5, 6, 7
    SQL

    execute <<-SQL
      CREATE OR REPLACE VIEW product_populations AS
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

      FROM population_movements as movements
      LEFT JOIN (
        SELECT
          SUM(delta) AS delta,
          product_id,
          started_at
        FROM population_movements
        GROUP BY product_id, started_at
      ) AS precedings
      ON movements.started_at >= precedings.started_at AND movements.product_id = precedings.product_id
      GROUP BY movements.id, movements.product_id, movements.started_at
    SQL
    execute 'CREATE OR REPLACE RULE delete_product_populations AS ON DELETE TO product_populations DO INSTEAD NOTHING;'
    execute 'CREATE OR REPLACE RULE delete_product_movements AS ON DELETE TO product_movements DO INSTEAD NOTHING;'
  end

  def down
    execute <<-SQL
      CREATE OR REPLACE VIEW product_populations AS
      SELECT DISTINCT ON (movements.started_at, movements.product_id)
        movements.product_id      AS product_id,
        movements.started_at      AS started_at,
        SUM(precedings.delta)     AS value,
        MAX(movements.creator_id) AS creator_id,
        MAX(movements.created_at) AS created_at,
        MAX(movements.updated_at) AS updated_at,
        MAX(movements.updater_id) AS updater_id,
        MIN(movements.id)         AS id,
        1                         AS lock_version

      FROM product_movements as movements
      LEFT JOIN (
        SELECT
          SUM(delta) AS delta,
          product_id,
          started_at
        FROM product_movements
        GROUP BY product_id, started_at
      ) AS precedings
      ON movements.started_at >= precedings.started_at AND movements.product_id = precedings.product_id
      GROUP BY movements.id, movements.product_id, movements.started_at
    SQL

    execute <<-SQL
      DROP VIEW population_movements
    SQL
  end
end
