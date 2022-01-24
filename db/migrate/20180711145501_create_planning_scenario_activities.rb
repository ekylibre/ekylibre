class CreatePlanningScenarioActivities < ActiveRecord::Migration
  def change
    unless data_source_exists?(:planning_scenario_activities)
      create_table :planning_scenario_activities do |t|
        t.references :activity, index: true, foreign_key: true
        t.references :planning_scenario, index: true, foreign_key: true
        t.integer :creator_id
        t.integer :updater_id
        t.timestamps null: false
      end
    end
  end
end
