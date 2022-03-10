class CreateWorkerTimeLogs < ActiveRecord::Migration[5.0]
  def change

    create_table :worker_time_logs do |t|
      t.references :worker, null: false, index: true
      t.datetime :started_at, null: false, index: true
      t.datetime :stopped_at, null: false, index: true
      t.integer :duration, null: false
      t.text :description
      t.jsonb :custom_fields, default: {}
      t.jsonb :provider, default: {}
      t.stamps
    end
    add_foreign_key :worker_time_logs, :products, column: :worker_id, on_delete: :cascade
    
  end
end
