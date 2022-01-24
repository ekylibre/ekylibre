class CreateActivityProductionIrregularBatches < ActiveRecord::Migration
  def change
    unless data_source_exists?(:activity_production_irregular_batches)
      create_table :activity_production_irregular_batches do |t|
        t.references :activity_production_batch, index: { name: :activity_production_irregular_batch_id }, foreign_key: true
        t.date :estimated_sowing_date
        t.decimal :area
        t.timestamps null: false
      end
    end
  end
end
