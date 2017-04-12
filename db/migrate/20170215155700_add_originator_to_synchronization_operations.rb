class AddOriginatorToSynchronizationOperations < ActiveRecord::Migration
  def change
    add_reference :synchronization_operations, :originator, polymorphic: true
  end
end
