# This migration comes from planning_engine (originally 20180226104505)
class CreateActivityProductionBatches < ActiveRecord::Migration
  def change
    create_table :activity_production_batches do |t|
      t.integer :number
      t.integer :day_interval
      t.boolean :irregular_batch, default: false
      t.references :activity_production, index: { name: :activity_production_batch_id }, foreign_key: true
      t.timestamps null: false
    end
  end
end
