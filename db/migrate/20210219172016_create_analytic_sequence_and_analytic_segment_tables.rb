class CreateAnalyticSequenceAndAnalyticSegmentTables < ActiveRecord::Migration[5.0]
  def change
    create_table :analytic_sequences do |t|
      t.timestamps
    end

    create_table :analytic_segments do |t|
      t.references :analytic_sequence, index: true, foreign_key: true, null: false
      t.string :name, null: false
      t.integer :position, null: false
      t.timestamps
    end
  end
end
