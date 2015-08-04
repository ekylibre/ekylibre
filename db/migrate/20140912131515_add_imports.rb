class AddImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.string :state,       null: false
      t.string :nature,      null: false
      t.attachment :archive
      t.references :importer
      t.datetime :imported_at
      t.decimal :progression_percentage, precision: 19, scale: 4
      t.stamps
      t.index :imported_at
    end
  end
end
