class CreatePlanningScenarioActivityPlots < ActiveRecord::Migration[4.2]
  def change
    unless data_source_exists?(:planning_scenario_activity_plots)
      create_table :planning_scenario_activity_plots do |t|
        t.references :planning_scenario_activity, index: { name: :index_activity_plots_on_scenario_activities_id }, foreign_key: true
        t.references :technical_itinerary, index: { name: :index_activity_plots_on_technical_itineraries_id }, foreign_key: true
        t.decimal :area
        t.date :planned_at
        t.integer :creator_id
        t.integer :updater_id
        t.boolean :batch_planting, default: false
        t.integer :number_of_batch
        t.integer :sowing_interval
        t.timestamps null: false
      end
    end
  end
end
