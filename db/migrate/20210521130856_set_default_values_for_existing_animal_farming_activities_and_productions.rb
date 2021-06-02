class SetDefaultValuesForExistingAnimalFarmingActivitiesAndProductions < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      UPDATE activities
      SET life_duration = COALESCE(life_duration, 20)
      WHERE production_cycle = 'perennial' and family = 'animal_farming'
    SQL

    execute <<-SQL
      UPDATE activity_productions
      SET stopped_on = COALESCE(stopped_on, (started_on + interval '20 year')::date),
          starting_year = COALESCE(starting_year, EXTRACT(YEAR FROM started_on))
      FROM activities
      WHERE activity_productions.activity_id = activities.id
        AND activities.production_cycle = 'perennial'
        AND activities.family = 'animal_farming'
    SQL
  end
end
