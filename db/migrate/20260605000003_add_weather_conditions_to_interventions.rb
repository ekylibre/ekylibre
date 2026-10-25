class AddWeatherConditionsToInterventions < ActiveRecord::Migration[5.2]
  def change
    add_column :interventions, :weather_conditions, :jsonb
  end
end
