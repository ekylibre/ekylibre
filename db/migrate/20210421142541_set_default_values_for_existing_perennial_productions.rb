class SetDefaultValuesForExistingPerennialProductions < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      UPDATE activity_productions
      SET stopped_on = COALESCE(stopped_on, (started_on + interval '50 year')::date),
          starting_year = COALESCE(starting_year, EXTRACT(YEAR FROM started_on))
      FROM activities
      WHERE activity_productions.activity_id = activities.id
        AND activities.production_cycle = 'perennial'
        AND ( activities.family = 'plant_farming' OR activities.family = 'vine_farming');
    SQL
  end
end
