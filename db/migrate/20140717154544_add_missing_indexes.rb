class AddMissingIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :analysis_items, :product_reading_id
    add_index :intervention_casts, :event_participation_id
    add_index :interventions, :event_id
    add_index :outgoing_delivery_items, :container_id
  end
end
