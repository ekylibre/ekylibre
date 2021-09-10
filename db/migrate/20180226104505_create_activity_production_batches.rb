class CreateActivityProductionBatches < ActiveRecord::Migration
  def change
    unless table_exists?(:activity_production_batches)
      create_table :activity_production_batches do |t|
        t.integer :number
        t.integer :day_interval
        t.boolean :irregular_batch, default: false
        t.references :activity_production, index: { name: :activity_production_batch_id }, foreign_key: true
        t.timestamps null: false
      end
    end
  end
end
