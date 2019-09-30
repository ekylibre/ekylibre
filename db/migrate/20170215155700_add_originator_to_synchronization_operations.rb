class AddOriginatorToSynchronizationOperations < ActiveRecord::Migration[4.2]
  def change
    add_reference :synchronization_operations, :originator, polymorphic: true
  end
end
