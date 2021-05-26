class SetDefaultValuesForExistingPerennialActivities < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      UPDATE activities
        SET life_duration = COALESCE(life_duration, 50),
          production_started_on = COALESCE(production_started_on, '2000-10-01'),
          production_stopped_on = COALESCE(production_stopped_on, '2000-09-30'),
          production_started_on_year = COALESCE(production_started_on_year, 0),
          production_stopped_on_year = COALESCE(production_stopped_on_year, 0),
          start_state_of_production_year = COALESCE(
                                             start_state_of_production_year,
                                             (
                                               CASE
                                               WHEN family = 'plant_farming'
                                                THEN 1
                                               ELSE 2
                                               END
                                             )
                                           )
        WHERE production_cycle = 'perennial' and ( family = 'plant_farming' OR family = 'vine_farming')
    SQL
  end
end
