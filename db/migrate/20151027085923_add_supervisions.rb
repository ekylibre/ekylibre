class AddSupervisions < ActiveRecord::Migration
  def change
    create_table :supervisions do |t|
      t.string :name, null: false
      t.integer :time_window
      t.json :view_parameters
      t.stamps
      t.index :name
    end

    create_table :supervision_items do |t|
      t.references :supervision, null: false, index: true
      t.references :sensor,      null: false, index: true
      t.string :color
      t.stamps
    end

    add_column :sensors, :token, :string

    reversible do |d|
      d.up do
        change_column_null :sensors, :vendor_euid, true
        change_column_null :sensors, :model_euid, true
        execute "UPDATE sensors SET retrieval_mode = 'requesting'"
      end
      d.down do
        execute "UPDATE sensors SET retrieval_mode = CASE WHEN active THEN 'automatic' ELSE 'manual' END"
      end
    end
  end
end
