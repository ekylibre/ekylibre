class FixFkWorkerContract < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :worker_contracts, :entities
    add_foreign_key :worker_contracts, :entities, column: :entity_id, on_delete: :cascade
  end
end
