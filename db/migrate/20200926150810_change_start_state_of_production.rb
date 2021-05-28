class ChangeStartStateOfProduction < ActiveRecord::Migration[4.2]
  def up
    add_column :activities, :start_state_of_production_year, :integer

    execute <<~SQL
      WITH activities2 AS (
        SELECT activities.id, jsonb_object_keys(start_state_of_production)::integer AS key_value
        FROM  activities
      )
      UPDATE activities activities1
      SET start_state_of_production_year = key_value
      FROM activities2
      WHERE activities2.id = activities1.id
    SQL

    remove_column :activities, :start_state_of_production
  end

  def down
    add_column :activities, :start_state_of_production, :jsonb, default: {}

    execute <<~SQL
      WITH activities2 AS (
        SELECT activities.id,
          jsonb_build_object(
            'n_' || jsonb_object_keys(start_state_of_production)::text,
            NULL
          ) AS start_state_of_production_jsonb
        FROM  activities
      )
      UPDATE activities activities1
      SET start_state_of_production = start_state_of_production_jsonb
      FROM activities2
      WHERE activities2.id = activities1.id
    SQL

    remove_column :activities, :start_state_of_production_year
  end
end