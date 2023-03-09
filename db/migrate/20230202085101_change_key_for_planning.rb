class ChangeKeyForPlanning < ActiveRecord::Migration[5.2]
  def change
    rename_column :technical_itineraries, :technical_workflow_id, :reference_name
  end
end
