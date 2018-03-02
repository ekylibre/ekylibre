# This migration comes from planning_engine (originally 20180227140040)
class CreateActivityProductionIrregularBatches < ActiveRecord::Migration
  def change
    create_table :activity_production_irregular_batches do |t|
      t.references :activity_production_batch, index: { name: :activity_production_irregular_batch_id }, foreign_key: true
      t.date :estimated_sowing_date
      t.decimal :area
      t.timestamps null: false
    end
  end
end
