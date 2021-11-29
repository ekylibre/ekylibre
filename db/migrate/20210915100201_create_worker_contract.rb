class CreateWorkerContract < ActiveRecord::Migration[5.0]
  def change
    create_table :worker_contracts do |t|
        t.references :entity, null: false, index: true
        t.string :name
        t.text :description
        t.string :reference_name
        t.string :nature
        t.string :contract_end
        t.datetime :started_at, null: false
        t.datetime :stopped_at
        t.boolean :salaried, null: false, default: false
        t.decimal :monthly_duration, precision: 8, scale: 2, null: false
        t.decimal :raw_hourly_amount, precision: 8, scale: 2, null: false
        t.stamps
      end
      add_foreign_key :worker_contracts, :entities, column: :entity_id
  end
end
