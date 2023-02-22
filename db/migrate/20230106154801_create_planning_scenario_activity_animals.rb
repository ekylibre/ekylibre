class CreatePlanningScenarioActivityAnimals < ActiveRecord::Migration[5.2]
  def change
    create_table :planning_scenario_activity_animals do |t|
      t.references :planning_scenario_activity, index: { name: :index_activity_animals_on_scenario_activities_id }, foreign_key: true
      t.references :technical_itinerary, index: { name: :index_activity_animals_on_technical_itineraries_id }, foreign_key: true
      t.integer :population
      t.date :planned_at
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps null: false
    end

    add_reference :daily_charges, :quantity_unit, index: true, foreign_key: { to_table: :units}
    add_column :daily_charges, :animal_population, :integer
  end
end
