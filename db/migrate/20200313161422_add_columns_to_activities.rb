class AddColumnsToActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :activities, :production_started_on, :date
    add_column :activities, :production_stopped_on, :date
    add_column :activities, :start_state_of_production, :jsonb
    add_column :activities, :life_duration, :integer
  end
end
