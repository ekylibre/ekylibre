class AddEkylibreColumnsToUnit < ActiveRecord::Migration[5.0]
  def change 
    change_table :units, bulk: true do |t|
      t.column :lock_version, :integer, null: false, default: 0
      t.references :creator, index: true
      t.references :updater, index: true
    end
  end
end
