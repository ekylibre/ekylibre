class CreatePlanningScenarios < ActiveRecord::Migration[4.2]
  def change
    unless data_source_exists?(:planning_scenarios)
      create_table :planning_scenarios do |t|
        t.string :name
        t.string :description
        t.references :campaign, index: true, foreign_key: true
        t.decimal :area
        t.integer :creator_id
        t.integer :updater_id
        t.timestamps null: false
      end
    end
  end
end
