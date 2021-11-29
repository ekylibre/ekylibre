class UpdateTacticForItks < ActiveRecord::Migration[5.0]
  def change
    remove_reference :technical_itineraries, :activity_tactic, index: true
    add_reference :activity_tactics, :technical_itinerary, index: true
    remove_reference :activity_tactics, :technical_workflow_sequence, index: true
    add_column :activity_tactics, :technical_sequence_id, :string, index: true
    add_column :technical_itineraries, :technical_workflow_id, :string, index: true
  end
end
